SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsUpdateLastMessage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsUpdateLastMessage]
	@TopicId int
	,@MessageId int
AS

UPDATE Topics
SET
	TopicReplies = TopicReplies + 1
	,LastMessageId = @MessageId
WHERE
	TopicId = @TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsUpdateLastMessage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsUpdateLastMessage]
	@TopicId int
	,@MessageId int
AS

UPDATE F
SET
	F.ForumMessageCount = F.ForumMessageCount + 1
FROM
	Topics T
	INNER JOIN Forums F ON F.ForumId = T.ForumId
WHERE
  T.TopicId = @TopicId;' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsUpdateRecount]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsUpdateRecount]
	@ForumId int = 2
AS
/*
	RECOUNTS THE CHILDREN MESSAGES AND TOPICS
*/
DECLARE @ForumTopicCount int, @ForumMessageCount int;

SELECT
	@ForumTopicCount = COUNT(TopicId)
	,@ForumMessageCount = SUM(TopicReplies)
FROM
	Topics
WHERE
	ForumId = @ForumId
	AND
	Active = 1;

UPDATE Forums
SET 
	ForumTopicCount = ISNULL(@ForumTopicCount, 0)
	,ForumMessageCount = ISNULL(@ForumMessageCount, 0)
WHERE	
	ForumId = @ForumId;' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTagsGetMostViewed]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTagsGetMostViewed]
	@ForumId int=2
	,@Top bigint=5
AS
SELECT
	Tag, 
	TagViews, 
	(TagViews*100.00)/SUM(case when TagViews > 0 then TagViews else 1 end) OVER() AS Weight
FROM
	(
	SELECT
		TOP (@Top)
		Tags.Tag
		,SUM(T.TopicViews) As TagViews
		,COUNT(T.TopicId) As TopicCount
	FROM
		Tags
		INNER JOIN Topics T ON Tags.TopicId = T.TopicId
	WHERE
		T.ForumId = @ForumId
		AND
		T.Active = 1
	GROUP BY
		Tags.Tag
	ORDER BY SUM(T.TopicViews) desc
	) T
ORDER BY Tag' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsClose]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsClose]
	@TopicId int
	,@UserId int
	,@Ip varchar(15)
AS
	UPDATE Topics
	SET
		TopicIsClose = 1
		,TopicLastEditDate = GETUTCDATE()
		,TopicLastEditUser = @UserId
		,TopicLastEditIp = @Ip
	WHERE
		TopicId = @TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsOpen]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsOpen]
	@TopicId int
	,@UserId int
	,@Ip varchar(15)
AS
	UPDATE Topics
	SET
		TopicIsClose = 0
		,TopicLastEditDate = GETUTCDATE()
		,TopicLastEditUser = @UserId
		,TopicLastEditIp = @Ip
	WHERE
		TopicId = @TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsAddVisit]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsAddVisit]
	@TopicId int=2
AS
UPDATE Topics
SET
	TopicViews = TopicViews+1
WHERE
	TopicId = @TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsSubscriptionsInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsSubscriptionsInsert]
	@TopicId int
	,@UserId int
AS
IF NOT EXISTS (SELECT TopicId FROM TopicsSubscriptions WHERE TopicId = @TopicId AND UserID = @UserId)
BEGIN
	INSERT INTO TopicsSubscriptions
	(TopicId, UserId)
	VALUES
	(@TopicId, @UserId)
END' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsSubscriptionsDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsSubscriptionsDelete]
	@TopicId int
	,@UserId int
	,@Userguid char(32)
AS
DELETE S
FROM 
	TopicsSubscriptions S
	INNER JOIN Users U ON U.UserId = S.UserId
WHERE
	S.TopicId = @TopicId
	AND
	S.UserId = @UserId	
	AND
	U.UserGuid = @UserGuid' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsSubscriptionsGetByTopic]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsSubscriptionsGetByTopic]
	@TopicId int
AS
SELECT
	U.UserId
	,U.UserName
	,U.UserEmail
	,U.UserEmailPolicy
	,U.UserGuid
FROM
	TopicsSubscriptions S
	INNER JOIN Users U ON U.UserId = S.UserId
WHERE
	TopicId = @TopicId
	AND
	U.Active = 1' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsGetByShortName]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsGetByShortName]
	@ShortName varchar(32)
AS
SELECT
	F.ForumId
	,F.ForumName
	,F.ForumShortName
	,F.ForumDescription
	,F.UserId
	,F.ForumCreationDate
	,F.ForumTopicCount
	,F.ForumMessageCount
	,C.CategoryId
	,C.CategoryName
FROM
	Forums F 
	INNER JOIN ForumsCategories C ON F.CategoryId = C.CategoryId
WHERE
	F.ForumShortName = @ShortName
	AND
	F.Active = 1' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsDelete]
	@ForumShortName varchar(32)
AS

UPDATE Forums
SET
	Active = 0
WHERE
	ForumShortName = @ForumShortName' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsInsert]
(
	@ForumName varchar(255)
	,@ForumShortName varchar(32)
	,@ForumDescription varchar(max)
	,@CategoryId int
	,@UserId int
)
AS
INSERT INTO Forums
(
	ForumName
	,ForumShortName
	,ForumDescription
	,CategoryId
	,UserId
	,ForumCreationDate
	,ForumLastEditDate
	,ForumLastEditUser
	,Active
	,ForumTopicCount
	,ForumMessageCount
	,ForumOrder
)
VALUES
(
	@ForumName
	,@ForumShortName
	,@ForumDescription
	,@CategoryId
	,@UserId
	,GETUTCDATE()
	,GETUTCDATE()
	,@UserId
	,1
	,0
	,0
	,0
)' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsUpdate]
(
	@ForumShortName varchar(32)
	,@ForumName varchar(255)
	,@ForumDescription varchar(max)
	,@CategoryId int
	,@UserId int
)
AS
UPDATE Forums
SET
	ForumName = @ForumName
	,ForumDescription = @ForumDescription 
	,CategoryId = @CategoryId
	,ForumLastEditDate = GETUTCDATE()
	,ForumLastEditUser = @UserId
WHERE
	ForumShortName = @ForumShortName' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsGetUsedShortNames]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsGetUsedShortNames]
(
	@ForumShortName varchar(32), 
	@SearchShortName varchar(32)
)
AS
/*
	Gets used short names for forums
	returns:
		IF NOT USED SHORTNAME: empty result set
		IF USED SHORTNAME: resultset with amount of rows used
*/
DECLARE @CurrentValue varchar(32)
SELECT 
	@CurrentValue = ForumShortName
FROM 
	Forums
WHERE
	ForumShortName = @ForumShortName
	

IF @CurrentValue IS NULL
	SELECT NULL As ForumShortName WHERE 1=0
ELSE
	SELECT 
		ForumShortName
	FROM
		Forums
	WHERE
		ForumShortName LIKE @SearchShortName + ''%''
		OR
		ForumShortName = @ForumShortName' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsGetByCategory]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsGetByCategory]
AS
SELECT
	F.ForumId
	,F.ForumName
	,F.ForumShortName
	,F.ForumDescription
	,F.UserId
	,F.ForumCreationDate
	,F.ForumTopicCount
	,F.ForumMessageCount
	,C.CategoryId
	,C.CategoryName
FROM
	ForumsCategories C
	INNER JOIN Forums F ON F.CategoryId = C.CategoryId
WHERE
	F.Active = 1
ORDER BY
	C.CategoryOrder,
	F.ForumOrder' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPPageContentsGetUsedShortNames]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[SPPageContentsGetUsedShortNames]
(
	@PageContentShortName varchar(32), 
	@SearchShortName varchar(32)
)
AS
/*
	Gets used short names for PageContents
	returns:
		IF NOT USED SHORTNAME: empty result set
		IF USED SHORTNAME: resultset with amount of rows used
*/
DECLARE @CurrentValue varchar(32)
SELECT 
	@CurrentValue = PageContentShortName
FROM 
	PageContents
WHERE
	PageContentShortName = @PageContentShortName
	

IF @CurrentValue IS NULL
	SELECT NULL As ForumShortName WHERE 1=0
ELSE
	SELECT 
		PageContentShortName
	FROM
		PageContents
	WHERE
		PageContentShortName LIKE @SearchShortName + ''%''
		OR
		PageContentShortName = @PageContentShortName

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPPageContentsInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[SPPageContentsInsert]
	@PageContentShortName varchar(128)
	,@PageContentTitle varchar(128)
	,@PageContentBody varchar(max)
AS
INSERT INTO PageContents 
(
PageContentTitle
,PageContentBody
,PageContentShortName
,PageContentEditDate
)
VALUES
(
@PageContentTitle
,@PageContentBody
,@PageContentShortName
,GETUTCDATE()
)

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPPageContentsDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[SPPageContentsDelete]
	@PageContentShortName varchar(128)
AS
DELETE FROM PageContents 
WHERE
	PageContentShortName = @PageContentShortName

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPPageContentsGet]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[SPPageContentsGet]
	@PageContentShortName varchar(128)=''about''
AS
SELECT
	PageContentId
	,PageContentTitle
	,PageContentBody
	,PageContentShortName
FROM
	dbo.PageContents
WHERE
	PageContentShortName = @PageContentShortName

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPPageContentsGetAll]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[SPPageContentsGetAll]
	
AS
SELECT
	PageContentId
	,PageContentTitle
	,PageContentBody
	,PageContentShortName
FROM
	dbo.PageContents
ORDER BY
	PageContentTitle

' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPPageContentsUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[SPPageContentsUpdate]
	@PageContentShortName varchar(128)
	,@PageContentTitle varchar(128)
	,@PageContentBody varchar(max)
AS
UPDATE PageContents 
SET
	PageContentTitle = @PageContentTitle
	,PageContentBody = @PageContentBody
	,PageContentEditDate = GETUTCDATE()
WHERE
	PageContentShortName = @PageContentShortName
' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesDelete]
	@TopicId int
	,@MessageId int
	,@UserId int
AS
UPDATE Messages
SET
	Active = 0
	,MessageLastEditDate = GETUTCDATE()
	,MessageLastEditUser = @UserId
WHERE
	TopicId = @TopicId
	AND
	MessageId = @MessageId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersPromote]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersPromote]
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
		UserId = @UserId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersDemote]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersDemote]
	@UserId int
AS
DECLARE @UserGroupId int
SELECT @UserGroupId = UserGroupId FROM Users WHERE UserId = @UserId
SELECT @UserGroupId = MAX(UserGroupId) FROM UsersGroups WHERE UserGroupId < @UserGroupId

IF @UserGroupId IS NOT NULL
	UPDATE Users
	SET
		UserGroupId = @UserGroupId
	WHERE
		UserId = @UserId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGetByName]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGetByName]
	@UserName varchar(50)=''Jorge''	
AS
SELECT
	U.UserId
	,U.UserName
	,U.UserProfile
	,U.UserSignature
	,U.UserGroupId
	,U.UserBirthDate
	,U.UserWebsite
	,U.UserTimezone
	,U.UserPhoto
	,U.UserRegistrationDate
	,UG.UserGroupId
	,UG.UserGroupName
FROM
	Users U
	INNER JOIN UsersGroups UG ON UG.UserGroupId = U.UserGroupId
WHERE
	U.UserName LIKE ''%'' + @UserName +  ''%''
	AND
	U.Active = 1
ORDER BY 
	U.UserName' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersUpdatePasswordResetGuid]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersUpdatePasswordResetGuid]
	@UserId int
	,@PasswordResetGuid varchar(100)
	,@PasswordResetGuidExpireDate datetime
AS
UPDATE Users
SET
	PasswordResetGuid = @PasswordResetGuid
	,PasswordResetGuidExpireDate = @PasswordResetGuidExpireDate
WHERE
	UserId = @UserId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGetByPasswordResetGuid]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGetByPasswordResetGuid]
	@Provider varchar(32)
	,@PasswordResetGuid varchar(64)
AS
SELECT 
	U.UserId
	,U.UserName
	,U.UserGroupId
	,U.UserGuid
	,U.UserTimeZone
	,U.UserExternalProfileUrl
	,U.UserProviderLastCall
	,U.UserEmail
	,U.UserProviderId
	,U.PasswordResetGuid
	,U.PasswordResetGuidExpireDate
FROM
	Users U
WHERE
	UserProvider = @Provider
	AND
	PasswordResetGuid = @PasswordResetGuid' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGetByProvider]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGetByProvider]
	@Provider varchar(32)
	,@ProviderId varchar(64)
AS
SELECT 
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
	UserProvider = @Provider
	AND
	UserProviderId = @ProviderId
	AND
	U.Active = 1' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGetAll]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGetAll]
AS
SELECT
	U.UserId
	,U.UserName
	,U.UserProfile
	,U.UserSignature
	,U.UserGroupId
	,U.UserBirthDate
	,U.UserWebsite
	,U.UserTimezone
	,U.UserPhoto
	,U.UserRegistrationDate
	,UG.UserGroupId
	,UG.UserGroupName
FROM
	Users U
	INNER JOIN UsersGroups UG ON UG.UserGroupId = U.UserGroupId
WHERE
	U.Active = 1
ORDER BY 
	U.UserName' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGet]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGet]
	@UserId int=11
AS
SELECT
	U.UserId
	,U.UserName
	,U.UserProfile
	,U.UserSignature
	,U.UserGroupId
	,U.UserBirthDate
	,U.UserWebsite
	,U.UserTimezone
	,U.UserPhoto
	,U.UserRegistrationDate
	,U.UserExternalProfileUrl
	,U.UserEmail
	,U.UserEmailPolicy
	,UG.UserGroupId
	,UG.UserGroupName
FROM
	Users U
	INNER JOIN UsersGroups UG ON UG.UserGroupId = U.UserGroupId
WHERE
	U.UserId = @UserId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersUpdateEmail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersUpdateEmail]
	@UserId int
	,@UserEmail varchar(100)
	,@UserEmailPolicy int
AS
UPDATE Users
SET
	UserEmail = @UserEmail
	,UserEmailPolicy = @UserEmailPolicy
WHERE
	UserId = @UserId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGetTestUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGetTestUser]
	
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
	U.UserGroupId DESC' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersInsertFromProvider]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersInsertFromProvider]
	(@UserName varchar(50)
	,@UserProfile varchar(max)
	,@UserSignature varchar(max)
	,@UserGroupId smallint
	,@UserBirthDate datetime
	,@UserWebsite varchar(255)
	,@UserGuid char(32)
	,@UserTimezone decimal(9,2)
	,@UserEmail varchar(100)
	,@UserEmailPolicy int
	,@UserPhoto varchar(1024)
	,@UserExternalProfileUrl varchar(255)
	,@UserProvider varchar(32)
	,@UserProviderId varchar(64))
AS

--If it is the first active user -> make it an admin
DECLARE @UserCount int
SELECT @UserCount=COUNT(UserId) FROM Users WHERE Active = 1
IF ISNULL(@UserCount, 0) = 0
	SELECT @UserGroupId = MAX(UserGroupId) FROM UsersGroups


INSERT INTO Users
   (UserName
   ,UserProfile
   ,UserSignature
   ,UserGroupId
   ,Active
   ,UserBirthDate
   ,UserWebsite
   ,UserGuid
   ,UserTimezone
   ,UserEmail
   ,UserEmailPolicy
   ,UserPhoto
   ,UserRegistrationDate
   ,UserExternalProfileUrl
   ,UserProvider
   ,UserProviderId
   ,UserProviderLastCall)
VALUES
	(@UserName
   ,@UserProfile
   ,@UserSignature
   ,@UserGroupId
   ,1 --Active
   ,@UserBirthDate
   ,@UserWebsite
   ,@UserGuid
   ,@UserTimezone
   ,@UserEmail
   ,@UserEmailPolicy
   ,@UserPhoto
   ,GETUTCDATE() --RegitrationDate
   ,@UserExternalProfileUrl
   ,@UserProvider
   ,@UserProviderId
   ,GETUTCDATE() --UserProviderLastCall
	);

DECLARE @UserId int;
SELECT @UserId = @@IDENTITY;
SELECT 	
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
	U.UserId = @UserId;' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersDelete]
	@UserId int
AS
UPDATE Users
SET	
	Active = 0
WHERE 
	UserId = @UserId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersUpdate]
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
	UserId = @UserId;' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTagsInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTagsInsert]
	@Tags varchar(256),
	@TopicId int,
	@PreviousTags varchar(256)=NULL
AS

IF NOT @PreviousTags IS NULL
	BEGIN
	DELETE FROM Tags
	WHERE
		Tag IN (SELECT part FROM dbo.Split(@PreviousTags, '' ''))
		AND
		TopicId = @TopicId
	END

INSERT INTO Tags
(Tag,TopicId)
SELECT part, @TopicId FROM dbo.Split(@Tags, '' '')' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesFlag]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesFlag]
(
	@TopicId int=1
	,@MessageId int=1
	,@Ip varchar(15)=''127.0.0.1''
)
AS
IF NOT EXISTS (SELECT * FROM Flags WHERE TopicId=@TopicId AND IP=@Ip AND (MessageId=@MessageId OR (@MessageId IS NULL AND MessageId IS NULL)))
	BEGIN
	INSERT INTO Flags
	(TopicId, MessageId, Ip, FlagDate)
	VALUES
	(@TopicId, @MessageId, @Ip, GETUTCDATE())
	END' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesFlagsClear]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesFlagsClear]
(
	@TopicId int=1
	,@MessageId int=1
)
AS
DELETE FROM 
	Flags
WHERE
	TopicId = @TopicId
	AND
	MessageId = @MessageId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPUsersGroupsGet]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPUsersGroupsGet]
	@UserGroupId smallint=1
AS
SELECT 
	UserGroupId
	,UserGroupName
FROM
	UsersGroups
WHERE
	UserGroupId = @UserGroupId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTemplatesInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTemplatesInsert]
	@TemplateKey varchar(16)
	,@TemplateDescription varchar(256)
	,@TemplateId int OUTPUT
AS
INSERT INTO Templates
(
	TemplateKey
	,TemplateDescription
	,TemplateDate
	,TemplateIsCurrent
)
VALUES
(
	@TemplateKey
	,@TemplateDescription
	,GETUTCDATE()
	,0
)

SELECT @TemplateId = @@IDENTITY' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTemplatesDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTemplatesDelete]
	@TemplateId int
AS
DELETE FROM Templates WHERE TemplateId = @TemplateId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTemplatesGet]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTemplatesGet]
	@TemplateId int
AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
	,TemplateIsCurrent
FROM
	Templates
WHERE
	TemplateId = @TemplateId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTemplatesGetCurrent]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTemplatesGetCurrent]

AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
FROM
	Templates
WHERE
	TemplateIsCurrent = 1' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTemplatesUpdateCurrent]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTemplatesUpdateCurrent]
	@TemplateId int
AS
UPDATE T
SET
	TemplateIsCurrent = 
		CASE WHEN TemplateId = @TemplateId THEN 1 ELSE 0 END
FROM
	Templates T' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTemplatesGetAll]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTemplatesGetAll]
AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
	,TemplateIsCurrent
FROM
	Templates' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPForumsCategoriesGetAll]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPForumsCategoriesGetAll]
AS
SELECT 
	CategoryId
	,CategoryName
	,CategoryOrder
FROM
	ForumsCategories
ORDER BY
	CategoryOrder' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsInsert]
(
	@TopicTitle varchar(255)
	,@TopicShortName varchar(64)
	,@TopicDescription varchar(max)
	,@UserId int
	,@TopicTags varchar(256)
	,@TopicOrder int
	,@Forum varchar(32)
	,@Ip varchar(15)
	,@TopicId int OUTPUT
)
AS
/*
- Inserts topic
- Insert tags
- Updates recount on father
*/

DECLARE @ForumId int

SELECT @ForumId = ForumId FROM Forums WHERE ForumShortName = @Forum
SET @TopicTags = LOWER(@TopicTags)

IF @TopicOrder IS NOT NULL
	BEGIN
	SELECT @TopicOrder = MAX(TopicOrder)+1 FROM Topics
	SELECT @TopicOrder = ISNULL(@TopicOrder, 1)
	END

BEGIN TRY
	BEGIN TRANSACTION
	
	INSERT INTO dbo.Topics
	(
	TopicTitle
	,TopicShortName
	,TopicDescription
	,TopicCreationDate
	,TopicLastEditDate
	,TopicViews
	,TopicReplies
	,UserId
	,TopicTags
	,ForumId
	,TopicLastEditUser
	,TopicLastEditIp
	,Active
	,TopicIsClose
	,TopicOrder
	,MessagesIdentity
	)
	VALUES
	(
	@TopicTitle
	,@TopicShortName
	,@TopicDescription
	,GETUTCDATE()
	,GETUTCDATE()
	,0--TopicViews
	,0--TopicReplies
	,@UserId
	,@TopicTags
	,@ForumId
	,@UserId
	,@Ip
	,1--Active
	,0--TopicIsClose
	,@TopicOrder
	,0--MessageIdentity
	);

	SELECT @TopicId = @@IDENTITY;

	--Add tags
	exec dbo.SPTagsInsert @Tags=@TopicTags, @TopicId=@TopicId;

	--Recount
	exec dbo.SPForumsUpdateRecount @ForumId=@ForumId;
	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

  -- Raise an error with the details of the exception
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		 @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)

END CATCH' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsMove]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsMove]
	@TopicId int
	,@ForumId int
	,@UserId int
	,@Ip varchar(15)
AS
DECLARE @PreviousForumId int
SELECT @PreviousForumId = ForumId FROM Topics WHERE TopicId = @TopicId
BEGIN TRY
	BEGIN TRANSACTION
	
	UPDATE Topics
	SET
		ForumId = @ForumId
		,TopicLastEditDate = GETUTCDATE()
		,TopicLastEditUser = @UserId
		,TopicLastEditIp = @Ip
	WHERE
		TopicId = @TopicId

	exec SPForumsUpdateRecount @ForumId
	exec SPForumsUpdateRecount @PreviousForumId

	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

  -- Raise an error with the details of the exception
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		 @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)

END CATCH' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesFlagsGetAll]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesFlagsGetAll]
AS
/*
	Lists all flagged messages (not topics)
*/
SELECT
	F.TopicId
	,F.MessageId
	,COUNT(FlagId) AS TotalFlags
	,T.TopicTitle
	,T.TopicShortName
	,Forums.ForumId
	,Forums.ForumShortName
	,Forums.ForumName
	,M.MessageBody
	,M.UserName
	,M.UserId
FROM
	Flags F
	INNER JOIN Topics T ON T.TopicId = F.TopicId
	INNER JOIN Forums ON Forums.ForumId = T.ForumId
	INNER JOIN MessagesComplete M ON M.TopicId = T.TopicId AND M.MessageId = F.MessageId
WHERE
	T.Active = 1
	AND	
	M.Active = 1
GROUP BY	
	F.TopicId
	,F.MessageId
	,T.TopicTitle
	,T.TopicShortName
	,Forums.ForumId
	,Forums.ForumShortName
	,Forums.ForumName
	,M.MessageBody
	,M.UserName
	,M.UserId
ORDER BY COUNT(FlagId) DESC, F.TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesInsert]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesInsert]
	@TopicId int
	,@MessageBody varchar(max)
	,@UserId int
	,@MessageId int OUTPUT
	,@Ip varchar(15)
	,@ParentId int
AS

UPDATE T
	SET
	MessagesIdentity = MessagesIdentity+1
	,@MessageId = MessagesIdentity+1
FROM
	Topics T
WHERE
	TopicId = @TopicId


BEGIN TRY
	BEGIN TRANSACTION

	INSERT INTO Messages
	(
	TopicId
	,MessageId
	,MessageBody
	,MessageCreationDate
	,MessageLastEditDate
	,MessageLastEditUser
	,UserId
	,Active
	,EditIp
	,ParentId
	)
	VALUES
	(
	@TopicId
	,@MessageId
	,@MessageBody
	,GETUTCDATE()
	,GETUTCDATE()
	,@UserId
	,@UserId
	,1
	,@Ip
	,@ParentId
	)


	
	--Update topic
	exec SPTopicsUpdateLastMessage @TopicId=@TopicId, @MessageId=@MessageId
	--Update forums
	exec SPForumsUpdateLastMessage @TopicId=@TopicId, @MessageId=@MessageId
	COMMIT

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

  -- Raise an error with the details of the exception
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		 @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)

END CATCH' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsDelete]
	@TopicId int
	,@UserId int
	,@Ip varchar(15)
AS
/*
- SETS THE TOPIC ACTIVE=0
- UPDATES RECOUNT ON FORUM
*/

DECLARE @ForumId int;
SELECT @ForumId = ForumId FROM Topics WHERE TopicId = @TopicId;

UPDATE Topics
SET
	Active = 0
	,TopicLastEditDate = GETUTCDATE()
	,TopicLastEditUser = @UserId
	,TopicLastEditIp = @Ip
WHERE
	TopicId = @TopicId;

exec dbo.SPForumsUpdateRecount @ForumId;' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsUpdate]
	@TopicId int
	,@TopicTitle varchar(256)
	,@TopicDescription varchar(max)
	,@UserId int
	,@TopicTags varchar(256)
	,@TopicOrder int
	,@Ip varchar(15)
AS
DECLARE @PreviousTags varchar(256)
SELECT @PreviousTags=TopicTags FROM Topics WHERE TopicId=@TopicId

IF @TopicOrder IS NOT NULL
	BEGIN
	SELECT @TopicOrder = MAX(TopicOrder)+1 FROM Topics
	SELECT @TopicOrder = ISNULL(@TopicOrder, 1)
	END

BEGIN TRY
	BEGIN TRANSACTION

	UPDATE T
	SET
		TopicTitle = @TopicTitle
		,TopicDescription = @TopicDescription
		,TopicLastEditDate = GETUTCDATE()
		,TopicTags = @TopicTags
		,TopicLastEditUser = @UserId
		,TopicLastEditIp = @Ip
		,TopicOrder = @TopicOrder
	FROM
		Topics T
	WHERE
		TopicId = @TopicId

	--Edit tags
	EXEC dbo.[SPTagsInsert] @Tags=@TopicTags, @TopicId=@TopicId, @PreviousTags=@PreviousTags

	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

  -- Raise an error with the details of the exception
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		 @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)

END CATCH' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsSubscriptionsGetByUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsSubscriptionsGetByUser]
	@UserId int=21
AS
SELECT
	T.TopicId
	,T.TopicTitle
	,T.TopicShortName
	,T.ForumId
	,T.ForumName
	,T.ForumShortName
FROM
	TopicsSubscriptions S
	INNER JOIN TopicsComplete T ON T.TopicId = S.TopicId
WHERE
	S.UserId = @UserId
ORDER BY
	S.TopicId DESC' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetByForumUnanswered]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetByForumUnanswered]
	@ForumId int = 2
AS
SELECT
	T.TopicId
	,T.TopicTitle
	,T.TopicShortName
	,T.TopicDescription
	,T.TopicCreationDate
	,T.TopicViews
	,T.TopicReplies
	,T.UserId
	,T.TopicTags
	,T.TopicIsClose
	,T.TopicOrder
	,T.LastMessageId
	,T.UserName
	,M.MessageCreationDate
FROM
	TopicsComplete T
	LEFT JOIN Messages M ON M.TopicId = T.TopicId AND M.MessageId = T.LastMessageId AND M.Active = 1
WHERE
	T.ForumId = @ForumId
	AND
	T.TopicReplies = 0 -- Unanswered
	AND
	T.TopicOrder IS NULL -- Not sticky	
ORDER BY 
	TopicViews DESC, TopicId DESC' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetByForum]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetByForum]
	@ForumId int = 2
	,@StartIndex int = 0
	,@Length int = 10
AS
SELECT
	*
FROM
	(SELECT
		ROW_NUMBER()
			OVER 
				(ORDER BY TopicOrder desc
				 ,TopicViews desc)
			AS RowNumber
		,T.TopicId
		,T.TopicTitle
		,T.TopicShortName
		,T.TopicDescription
		,T.TopicCreationDate
		,T.TopicViews
		,T.TopicReplies
		,T.UserId
		,T.TopicTags
		,T.TopicIsClose
		,T.TopicOrder
		,T.LastMessageId
		,T.UserName
		,M.MessageCreationDate
	FROM
		TopicsComplete T
		LEFT JOIN Messages M ON M.TopicId = T.TopicId AND M.MessageId = T.LastMessageId AND M.Active = 1
	WHERE
		T.ForumId = @ForumId
	) T
WHERE
	RowNumber BETWEEN @StartIndex+1 AND @StartIndex + @Length' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetUnanswered]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetUnanswered]
AS
SELECT
	T.TopicId
	,T.TopicTitle
	,T.TopicShortName
	,T.TopicDescription
	,T.TopicCreationDate
	,T.TopicViews
	,T.TopicReplies
	,T.UserId
	,T.TopicTags
	,T.TopicIsClose
	,T.TopicOrder
	,T.LastMessageId
	,T.UserName
	,M.MessageCreationDate
	,T.ForumId
	,T.ForumName
	,T.ForumShortName
FROM
	TopicsComplete T
	LEFT JOIN Messages M ON M.TopicId = T.TopicId AND M.MessageId = T.LastMessageId AND M.Active = 1
WHERE
	T.TopicReplies = 0 -- Unanswered
	AND
	T.TopicOrder IS NULL -- Not sticky	
ORDER BY 
	TopicId DESC' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetByUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetByUser]
	@UserId int	
AS
SELECT
	T.TopicId
	,T.TopicTitle
	,T.TopicShortName
	,T.TopicDescription
	,T.TopicCreationDate
	,T.TopicViews
	,T.TopicReplies
	,T.UserId
	,T.TopicTags
	,T.TopicIsClose
	,T.TopicOrder
	,T.LastMessageId
	,T.UserName
	,M.MessageCreationDate
FROM
	TopicsComplete T
	LEFT JOIN Messages M ON M.TopicId = T.TopicId AND M.MessageId = T.LastMessageId AND M.Active = 1
WHERE
	T.UserId = @UserId
ORDER BY T.TopicId desc' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetMessagesByUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetMessagesByUser]
	@UserId int	
AS
/*
Gets the messages posted by the user grouped by topic
*/
SELECT
	T.TopicId
	,M.MessageId
	,M.MessageCreationDate
	,T.TopicTitle
	,T.TopicShortName
	,T.TopicDescription
	,T.TopicCreationDate
	,T.TopicViews
	,T.TopicReplies
	,T.UserId
	,T.TopicTags
	,T.TopicIsClose
	,T.TopicOrder
FROM
	TopicsComplete T
	INNER JOIN Messages M ON M.TopicId = T.TopicId
WHERE
	M.UserId = @UserId
ORDER BY T.TopicId desc, M.MessageId desc' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetByForumLatest]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetByForumLatest]
	@ForumId int = 2
	,@StartIndex int = 0
	,@Length int = 10
AS
SELECT
	*
FROM
	(SELECT
		ROW_NUMBER()
			OVER 
				(ORDER BY T.TopicId desc)
			AS RowNumber
		,T.TopicId
		,T.TopicTitle
		,T.TopicShortName
		,T.TopicDescription
		,T.TopicCreationDate
		,T.TopicViews
		,T.TopicReplies
		,T.UserId
		,T.TopicTags
		,T.TopicIsClose
		,T.TopicOrder
		,T.LastMessageId
		,T.UserName
		,M.MessageCreationDate
	FROM
		TopicsComplete T
		LEFT JOIN Messages M ON M.TopicId = T.TopicId AND M.MessageId = T.LastMessageId AND M.Active = 1
	WHERE
		T.ForumId = @ForumId
	) T
WHERE
	RowNumber BETWEEN @StartIndex+1 AND @StartIndex + @Length' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetLatest]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetLatest]
AS
	SELECT
		TOP 20
		T.TopicId
		,T.TopicTitle
		,T.TopicShortName
		,T.TopicDescription
		,T.TopicCreationDate
		,T.TopicViews
		,T.TopicReplies
		,T.UserId
		,T.TopicTags
		,T.TopicIsClose
		,T.TopicOrder
		,T.LastMessageId
		,T.UserName
		,M.MessageCreationDate
	FROM
		TopicsComplete T
		LEFT JOIN Messages M ON M.TopicId = T.TopicId AND M.MessageId = T.LastMessageId AND M.Active = 1
	
	ORDER BY T.TopicId desc' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetByRelated]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetByRelated]
	@Tag1 varchar(50)=''problem''
	,@Tag2 varchar(50)=''installation''
	,@Tag3 varchar(50)=''copy''
	,@Tag4 varchar(50)=null
	,@Tag5 varchar(50)=null
	,@Tag6 varchar(50)=null
	,@TopicId int=1
	,@Amount int=5
AS
	
WITH TagsParams (Tag) AS
(
	SELECT @Tag1
	UNION
	SELECT @Tag2
	UNION
	SELECT @Tag3
	UNION
	SELECT @Tag4
	UNION
	SELECT @Tag5
	UNION
	SELECT @Tag6
)
SELECT
	TOP (@Amount)
	Ta.TagCount
	,Topics.TopicId
	,Topics.TopicTitle
	,Topics.TopicShortName
	,Topics.TopicDescription
	,Topics.TopicCreationDate
	,Topics.TopicViews
	,Topics.TopicReplies
	,Topics.ForumId
	,Topics.ForumName
	,Topics.ForumShortName
	,Topics.TopicIsClose
	,Topics.TopicOrder
FROM
	(
	SELECT 
		T.TopicId
		,COUNT(T.Tag) AS TagCount
	FROM 
		Tags T
		INNER JOIN TagsParams P ON T.Tag=P.Tag
	WHERE
		T.Tag=P.Tag
	GROUP BY
		T.TopicId
	)
	Ta
	INNER JOIN TopicsComplete Topics ON Topics.TopicId = Ta.TopicId
WHERE
	Topics.TopicId <> @TopicId
ORDER BY
	1 desc, Topics.TopicViews desc' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGetByTag]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGetByTag]
	@Tag varchar(50)=''forum'',
	@ForumId int=2
AS

--Remove the last char
SET @Tag = SUBSTRING(@Tag, 1, LEN(@Tag)-1)
SELECT
		T.TopicId
		,T.TopicTitle
		,T.TopicShortName
		,T.TopicDescription
		,T.TopicCreationDate
		,T.TopicViews
		,T.TopicReplies
		,T.UserId
		,T.TopicTags
		,T.TopicIsClose
		,T.TopicOrder
		,T.LastMessageId
		,T.UserName
FROM
	Tags
	INNER JOIN TopicsComplete T ON T.TopicId = Tags.TopicId
WHERE
	Tags.Tag LIKE @Tag + ''%''
	AND
	T.ForumId = @ForumId
ORDER BY TopicOrder DESC,TopicViews DESC' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPTopicsGet]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPTopicsGet]
	@TopicId int=1
AS
SELECT
	T.TopicId
	,T.TopicTitle
	,T.TopicShortName
	,T.TopicDescription
	,T.TopicCreationDate
	,T.TopicViews
	,T.TopicReplies
	,T.UserId
	,T.TopicTags
	,T.TopicIsClose
	,T.TopicOrder
	,T.LastMessageId
	,T.UserName
	,T.ForumId
	,T.ForumName
	,T.ForumShortName
FROM 
	TopicsComplete T
WHERE
	T.TopicId = @TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesGetByTopicLatest]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesGetByTopicLatest]
	@TopicId int=2
AS
SELECT 
	TOP 20
	M.TopicId
	,M.MessageId
	,M.MessageBody
	,M.MessageCreationDate
	,M.MessageLastEditDate
	,M.ParentId
	,UserId
	,UserName
	,UserSignature
	,UserGroupId
	,UserGroupName
	,M.Active
FROM 
	dbo.MessagesComplete M
WHERE 
	M.TopicId = @TopicId
ORDER BY
	TopicId, MessageId DESC' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesGetByTopicUpTo]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesGetByTopicUpTo]
	@TopicId int=1,
	@FirstMsg int=14,
	@LastMsg int=28
AS
SELECT 
	ROW_NUMBER()
			OVER 
				(ORDER BY M.TopicId, M.MessageId)
			AS RowNumber
	,M.TopicId
	,M.MessageId
	,M.MessageBody
	,M.MessageCreationDate
	,M.MessageLastEditDate
	,M.ParentId
	,UserId
	,UserName
	,UserSignature
	,UserGroupId
	,UserGroupName
	,M.Active
FROM 
	dbo.MessagesComplete M
WHERE 
	M.TopicId = @TopicId
	AND
	M.MessageId > @FirstMsg
	AND
	M.MessageId <= @LastMsg' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesGetByTopic]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesGetByTopic]
	@TopicId int=2
AS
SELECT 
	ROW_NUMBER()
			OVER 
				(ORDER BY M.TopicId, M.MessageId)
			AS RowNumber
	,M.TopicId
	,M.MessageId
	,M.MessageBody
	,M.MessageCreationDate
	,M.MessageLastEditDate
	,M.ParentId
	,UserId
	,UserName
	,UserSignature
	,UserGroupId
	,UserGroupName
	,M.Active
FROM 
	dbo.MessagesComplete M
WHERE 
	M.TopicId = @TopicId' 
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SPMessagesGetByTopicFrom]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[SPMessagesGetByTopicFrom]
	@TopicId int=1,
	@FirstMsg int=13,
	@Amount int=10
AS
SELECT
*
FROM
	(
	SELECT 
		ROW_NUMBER()
				OVER 
					(ORDER BY M.TopicId, M.MessageId)
				AS RowNumber
		,M.TopicId
		,M.MessageId
		,M.MessageBody
		,M.MessageCreationDate
		,M.MessageLastEditDate
		,M.ParentId
		,UserId
		,UserName
		,UserSignature
		,UserGroupId
		,UserGroupName
		,M.Active
	FROM 
		dbo.MessagesComplete M
	WHERE 
		M.TopicId = @TopicId
		AND
		M.MessageId > @FirstMsg
	) M
WHERE
	RowNumber <= @Amount' 
END