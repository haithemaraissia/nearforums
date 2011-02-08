SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPUsersGetTestUser]
	
AS
SELECT 
	Top 1
	U.UserId
	,U.UserName
	,U.UserGroupId
	,U.UserGuid
	,U.UserTimeZone
	,U.UserExternalProfileUrl
	,U.UserProviderLastCall
	,U.UserEmail
FROM
	Users U
WHERE
	U.Active = 1
ORDER BY
	U.UserGroupId DESC


GO
