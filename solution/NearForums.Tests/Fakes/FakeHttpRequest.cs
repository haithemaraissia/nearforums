﻿using System;
using System.Collections.Specialized;
using System.Web;

namespace NearForums.Tests.Fakes
{

    public class FakeHttpRequest : HttpRequestBase
    {
        private readonly NameValueCollection _formParams;
        private readonly NameValueCollection _queryStringParams;
        private readonly HttpCookieCollection _cookies;
		private Uri _uri;
		private NameValueCollection _headers = new NameValueCollection();

        public FakeHttpRequest(string url, NameValueCollection formParams, NameValueCollection queryStringParams, HttpCookieCollection cookies)
        {
			_uri = new Uri(url);
            _formParams = formParams;
            _queryStringParams = queryStringParams;
            _cookies = cookies;
        }

        public override NameValueCollection Form
        {
            get
            {
                return _formParams;
            }
        }

        public override NameValueCollection QueryString
        {
            get
            {
                return _queryStringParams;
            }
        }

		public override NameValueCollection Headers
		{
			get
			{
				return _headers;
			}
		}

        public override HttpCookieCollection Cookies
        {
            get
            {
                return _cookies;
            }
        }

		public override string AppRelativeCurrentExecutionFilePath
		{
			get
			{
				return "~" + this.Url.AbsolutePath;
			}
		}

		public override string PathInfo
		{
			get
			{
				return "";
			}
		}

		public override string ApplicationPath
		{
			get
			{
				return "";
			}
		}

		public override Uri Url
		{
			get
			{
				return _uri;
			}
		}

		public void SetUri(string url)
		{
			this._uri = new Uri(url);
		}

		public override string UserHostAddress
		{
			get
			{
				return "127.0.0.1";
			}
		}

		public override string HttpMethod
		{
			get
			{
				return "GET";
			}
		}

    }



}
