﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using NearForums.Web.Controllers.Helpers;
using NearForums.ServiceClient;
using NearForums.Web.Extensions;

namespace NearForums.Web.Controllers
{
	public class HomeController : BaseController
	{
		public ActionResult Index()
		{
			return View(null, "Site", null);
		}

		public ActionResult About()
		{
			return Static("About", true);
		}

		/// <summary>
		/// This action throws an exception. Use this action to test the logging
		/// </summary>
		public ActionResult Error()
		{
			if (this.User != null && this.User.Group == UserGroup.Admin)
			{
				throw new Exception("This is a dummy exception thrown by the nearforums application.");
			}
			return ResultHelper.NotFoundResult(this);
		}

		/// <summary>
		/// This action is used when another action was not found.
		/// </summary>
		/// <returns></returns>
		public ActionResult NotFound()
		{
			return ResultHelper.NotFoundResult(this);
		}
	}
}
