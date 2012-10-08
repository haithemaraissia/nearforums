﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Configuration;
using NearForums.Validation;

namespace NearForums.Configuration
{
	public class UIElement : BaseConfigurationElement, IEnsureValidation
	{
		/// <summary>
		/// Determines the amount of messages per page are shown on the topic detail page
		/// </summary>
		[ConfigurationProperty("messagesPerPage", DefaultValue=10)]
		public int MessagesPerPage
		{
			get
			{
				return (int)this["messagesPerPage"];
			}
			set
			{
				this["messagesPerPage"] = value;
			}
		}

		/// <summary>
		/// Determines the amount of topics per page are shown on the forum detail page
		/// </summary>
		[ConfigurationProperty("topicsPerPage", DefaultValue=20)]
		public int TopicsPerPage
		{
			get
			{
				return (int)this["topicsPerPage"];
			}
			set
			{
				this["topicsPerPage"] = value;
			}
		}
		/// <summary>
		/// Amount of tags in the tag cloud
		/// </summary>
		[ConfigurationProperty("tagsCloudCount", DefaultValue=30)]
		public int TagsCloudCount
		{
			get
			{
				return (int)this["tagsCloudCount"];
			}
			set
			{
				this["tagsCloudCount"] = value;
			}
		}

		/// <summary>
		/// Date Format string .NET http://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
		/// </summary>
		[ConfigurationProperty("dateFormat", DefaultValue="U")]
		public string DateFormat
		{
			get
			{
				return (string)this["dateFormat"];
			}
			set
			{
				this["dateFormat"] = value;
			}
		}

		[ConfigurationProperty("template")]
		public TemplateElement Template
		{
			get
			{
				return (TemplateElement)this["template"];
			}
			set
			{
				this["template"] = value;
			}
		}

		[ConfigurationProperty("resources")]
		public ResourcesElement Resources
		{
			get
			{
				return (ResourcesElement)this["resources"];
			}
			set
			{
				this["resources"] = value;
			}
		}

		/// <summary>
		/// Determines if user details (image, member since, ...) are shown on topic detail page
		/// </summary>
		[ConfigurationProperty("showUserDetailsOnList", DefaultValue=true)]
		public bool ShowUserDetailsOnList
		{
			get
			{
				return (bool)this["showUserDetailsOnList"];
			}
			set
			{
				this["showUserDetailsOnList"] = value;
			}
		}

		/// <summary>
		/// Determines which is the default forum sorting of topics
		/// </summary>
		[ConfigurationProperty("defaultForumSort", DefaultValue = ForumSort.LatestActivity)]
		public ForumSort DefaultForumSort
		{
			get
			{
				return (ForumSort)this["defaultForumSort"];
			}
			set
			{
				this["defaultForumSort"] = value;
			}
		}

		#region IEnsureValidation Members

		public void ValidateFields()
		{
			throw new NotImplementedException();
		}

		#endregion
	}
}
