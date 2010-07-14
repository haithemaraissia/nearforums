﻿namespace NearForums.Web.Controllers.Helpers.OAuth
{
	using System;
	using System.Collections.Generic;
	using System.Configuration;
	using System.Globalization;
	using System.IO;
	using System.Net;
	using System.Web;
	using System.Xml;
	using System.Xml.Linq;
	using System.Xml.XPath;
	using DotNetOpenAuth.Messaging;
	using DotNetOpenAuth.OAuth;
	using DotNetOpenAuth.OAuth.ChannelElements;
	using DotNetOpenAuth.OAuth.Messages;

	/// <summary>
	/// A consumer capable of communicating with Twitter.
	/// </summary>
	public static class TwitterConsumer
	{
		/// <summary>
		/// The description of Twitter's OAuth protocol URIs for use with actually reading/writing
		/// a user's private Twitter data.
		/// </summary>
		public static readonly ServiceProviderDescription ServiceDescription = new ServiceProviderDescription
		{
			RequestTokenEndpoint = new MessageReceivingEndpoint("http://twitter.com/oauth/request_token", HttpDeliveryMethods.GetRequest | HttpDeliveryMethods.AuthorizationHeaderRequest),
			UserAuthorizationEndpoint = new MessageReceivingEndpoint("http://twitter.com/oauth/authorize", HttpDeliveryMethods.GetRequest | HttpDeliveryMethods.AuthorizationHeaderRequest),
			AccessTokenEndpoint = new MessageReceivingEndpoint("http://twitter.com/oauth/access_token", HttpDeliveryMethods.GetRequest | HttpDeliveryMethods.AuthorizationHeaderRequest),
			TamperProtectionElements = new ITamperProtectionChannelBindingElement[] { new HmacSha1SigningBindingElement() },
		};

		/// <summary>
		/// The URI to get a user's favorites.
		/// </summary>
		private static readonly MessageReceivingEndpoint GetFavoritesEndpoint = new MessageReceivingEndpoint("http://twitter.com/favorites.xml", HttpDeliveryMethods.GetRequest);

		/// <summary>
		/// The URI to get the data on the user's home page.
		/// </summary>
		private static readonly MessageReceivingEndpoint GetFriendTimelineStatusEndpoint = new MessageReceivingEndpoint("http://twitter.com/statuses/friends_timeline.xml", HttpDeliveryMethods.GetRequest);

		private static readonly MessageReceivingEndpoint UpdateProfileBackgroundImageEndpoint = new MessageReceivingEndpoint("http://twitter.com/account/update_profile_background_image.xml", HttpDeliveryMethods.PostRequest | HttpDeliveryMethods.AuthorizationHeaderRequest);

		private static readonly MessageReceivingEndpoint UpdateProfileImageEndpoint = new MessageReceivingEndpoint("http://twitter.com/account/update_profile_image.xml", HttpDeliveryMethods.PostRequest | HttpDeliveryMethods.AuthorizationHeaderRequest);

		private static readonly MessageReceivingEndpoint VerifyCredentialsEndpoint = new MessageReceivingEndpoint("http://api.twitter.com/1/account/verify_credentials.xml", HttpDeliveryMethods.GetRequest | HttpDeliveryMethods.AuthorizationHeaderRequest);

		private static readonly MessageReceivingEndpoint GetUserEndPoint = new MessageReceivingEndpoint("http://api.twitter.com/1/users/show.xml", HttpDeliveryMethods.GetRequest);

		/// <summary>
		/// The lock acquired to initialize the <see cref="signInConsumer"/> field.
		/// </summary>
		private static object signInConsumerInitLock = new object();

		/// <summary>
		/// Initializes static members of the <see cref="TwitterConsumer"/> class.
		/// </summary>
		static TwitterConsumer()
		{
			// Twitter can't handle the Expect 100 Continue HTTP header. 
			ServicePointManager.FindServicePoint(GetFavoritesEndpoint.Location).Expect100Continue = false;
		}

		public static XDocument GetUpdates(ConsumerBase twitter, string accessToken)
		{
			IncomingWebResponse response = twitter.PrepareAuthorizedRequestAndSend(GetFriendTimelineStatusEndpoint, accessToken);
			return XDocument.Load(XmlReader.Create(response.GetResponseReader()));
		}

		public static XDocument GetFavorites(ConsumerBase twitter, string accessToken)
		{
			IncomingWebResponse response = twitter.PrepareAuthorizedRequestAndSend(GetFavoritesEndpoint, accessToken);
			return XDocument.Load(XmlReader.Create(response.GetResponseReader()));
		}

		public static XDocument UpdateProfileBackgroundImage(ConsumerBase twitter, string accessToken, string image, bool tile)
		{
			var parts = new[] {
				MultipartPostPart.CreateFormFilePart("image", image, "image/" + Path.GetExtension(image).Substring(1).ToLowerInvariant()),
				MultipartPostPart.CreateFormPart("tile", tile.ToString().ToLowerInvariant()),
			};
			HttpWebRequest request = twitter.PrepareAuthorizedRequest(UpdateProfileBackgroundImageEndpoint, accessToken, parts);
			request.ServicePoint.Expect100Continue = false;
			IncomingWebResponse response = twitter.Channel.WebRequestHandler.GetResponse(request);
			string responseString = response.GetResponseReader().ReadToEnd();
			return XDocument.Parse(responseString);
		}

		public static XDocument UpdateProfileImage(ConsumerBase twitter, string accessToken, string pathToImage)
		{
			string contentType = "image/" + Path.GetExtension(pathToImage).Substring(1).ToLowerInvariant();
			return UpdateProfileImage(twitter, accessToken, File.OpenRead(pathToImage), contentType);
		}

		public static XDocument UpdateProfileImage(ConsumerBase twitter, string accessToken, Stream image, string contentType)
		{
			var parts = new[] {
				MultipartPostPart.CreateFormFilePart("image", "twitterPhoto", contentType, image),
			};
			HttpWebRequest request = twitter.PrepareAuthorizedRequest(UpdateProfileImageEndpoint, accessToken, parts);
			IncomingWebResponse response = twitter.Channel.WebRequestHandler.GetResponse(request);
			string responseString = response.GetResponseReader().ReadToEnd();
			return XDocument.Parse(responseString);
		}

		public static XDocument VerifyCredentials(ConsumerBase twitter, string accessToken)
		{
			IncomingWebResponse response = twitter.PrepareAuthorizedRequestAndSend(VerifyCredentialsEndpoint, accessToken);
			return XDocument.Load(XmlReader.Create(response.GetResponseReader()));
		}

		public static TwitterUser GetUserFromCredentials(IConsumerTokenManager tokenManager, string accessToken)
		{
			WebConsumer twitter = new WebConsumer(TwitterConsumer.ServiceDescription, tokenManager);
			XDocument xml = VerifyCredentials(twitter, accessToken);
			XPathNavigator nav = xml.CreateNavigator();
			return new TwitterUser(nav);
		}

		/// <summary>
		/// Tries to get information the service provider and revalidates it.
		/// </summary>
		/// <param name="tokenManager"></param>
		/// <param name="reissueOnFail">Determines if the flow should be restarted when the parameters are incorrect (due to token invalid or expired).</param>
		/// <param name="userId"></param>
		/// <param name="accessToken"></param>
		/// <returns></returns>
		public static bool TryFinishOAuthFlow(IConsumerTokenManager tokenManager, bool reissueOnFail, out long userId, out string accessToken)
		{
			bool success = false;
			var twitter = new WebConsumer(TwitterConsumer.ServiceDescription, tokenManager);
			userId = 0;
			accessToken = null;
			// Is Twitter calling back with authorization?
			try
			{
				var accessTokenResponse = twitter.ProcessUserAuthorization();
				if (accessTokenResponse != null)
				{
					accessToken = accessTokenResponse.AccessToken;
					userId = Convert.ToInt64(accessTokenResponse.ExtraData["user_id"]);
					success = true;
				}
			}
			catch (DotNetOpenAuth.Messaging.ProtocolException)
			{
				//Restart process
				if (reissueOnFail)
				{
					StartOAuthFlow(tokenManager);
				}
			}
			return success;
		}

		/// <summary>
		/// Starts OAuth by getting a request Token and redirecting the user to the provider.
		/// </summary>
		/// <param name="tokenManager"></param>
		public static void StartOAuthFlow(IConsumerTokenManager tokenManager)
		{
			var twitter = new WebConsumer(TwitterConsumer.ServiceDescription, tokenManager);
			UserAuthorizationRequest usr = twitter.PrepareRequestUserAuthorization();
			twitter.Channel.Send(usr);
		}

		#region Twitter User
		public class TwitterUser
		{
			public TwitterUser(XPathNavigator nav)
			{
				//http://apiwiki.twitter.com/Twitter-REST-API-Method:-users%C2%A0show
				var nodes = nav.Select("user/*");
				foreach (XPathNavigator navItem in nodes)
				{
					switch (navItem.Name)
					{
						case "id":
							this.Id = Convert.ToInt64(navItem.Value);
							break;
						case "name":
							this.Name = navItem.Value;
							break;
						case "screen_name":
							this.ScreenName = navItem.Value;
							break;
						case "profile_image_url":
							this.ProfileImageUrl = navItem.Value;
							break;
						case "description":
							this.Description = navItem.Value;
							break;
						case "utc_offset":
							this.TimeZone = Convert.ToDecimal(navItem.Value) / 3600m;
							break;
					}
				}
			}

			public long Id
			{
				get;
				set;
			}

			public string Name
			{
				get;
				set;
			}

			public string ScreenName
			{
				get;
				set;
			}

			public string ProfileUrl
			{
				get
				{
					return "http://twitter.com/" + this.ScreenName;
				}
			}

			public string ProfileImageUrl
			{
				get;
				set;
			}

			public string Description
			{
				get;
				set;
			}

			/// <summary>
			/// UTC offset expressed in hours
			/// </summary>
			public decimal TimeZone
			{
				get;
				set;
			}
		}
		#endregion
	}
}
