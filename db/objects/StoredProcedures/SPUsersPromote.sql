SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SPUsersPromote
	@UserId int
AS
DECLARE @UserGroupId int
SELECT @UserGroupId = UserGroupId FROM Users WHERE UserId = @UserId
SELECT @UserGroupId = MIN(UserGroupId) FROM UsersGroups WHERE UserGroupId > @UserGroupId

IF @UserGroupId IS NOT NULL
	UPDATE Users
	SET
		UserGroupId = @UserGroupId
	WHERE
		UserId = @UserId
GO
