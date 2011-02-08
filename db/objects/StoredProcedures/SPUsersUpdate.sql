SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SPUsersUpdate
	@UserId int
	,@UserName varchar(50)
	,@UserProfile varchar(max)
	,@UserSignature varchar(max)
	,@UserBirthDate datetime
	,@UserWebsite varchar(255)
	,@UserTimezone decimal(9,2)
	,@UserEmail varchar(100)
	,@UserEmailPolicy int
	,@UserPhoto varchar(1024)
	,@UserExternalProfileUrl varchar(255)
AS

UPDATE Users
SET 
UserName = @UserName
,UserProfile = @UserProfile
,UserSignature = @UserSignature
,UserBirthDate = @UserBirthDate
,UserWebsite = @UserWebsite
,UserTimezone = @UserTimezone
,UserEmail = @UserEmail
,UserEmailPolicy = @UserEmailPolicy
,UserPhoto = @UserPhoto
,UserExternalProfileUrl = @UserExternalProfileUrl
WHERE 
	UserId = @UserId;
GO
