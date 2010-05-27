SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTopicsUpdateLastMessage]
	@TopicId int
	,@MessageId int
AS

UPDATE Topics
SET
	TopicReplies = TopicReplies + 1
	,LastMessageId = @MessageId
WHERE
	TopicId = @TopicId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTemplatesGet]
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
	TemplateId = @TemplateId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTemplatesGetCurrent]

AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
FROM
	Templates
WHERE
	TemplateIsCurrent = 1

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTemplatesUpdateCurrent]
	@TemplateId int
AS
UPDATE T
SET
	TemplateIsCurrent = 
		CASE WHEN TemplateId = @TemplateId THEN 1 ELSE 0 END
FROM
	Templates T
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTemplatesGetAll]
AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
	,TemplateIsCurrent
FROM
	Templates

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPForumsGetByShortName]
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
	F.Active = 1
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPForumsUpdateRecount]
	@ForumId int = 2
AS
/*
	RECOUNTS THE CHILDREN MESSAGES AND TOPICS
*/
DECLARE @ForumTopicCount int, @ForumMessageCount int

SELECT
	@ForumTopicCount = COUNT(TopicId)
	,@ForumMessageCount = SUM(TopicReplies)
FROM
	Topics
WHERE
	ForumId = @ForumId

UPDATE Forums
SET 
	ForumTopicCount = ISNULL(@ForumTopicCount, 0)
	,ForumMessageCount = ISNULL(@ForumMessageCount, 0)
WHERE	
	ForumId = @ForumId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPForumsUpdateLastMessage]
	@TopicId int
	,@MessageId int
AS

UPDATE F
SET
	F.ForumMessageCount = F.ForumMessageCount + 1
FROM
	Forums F
	INNER JOIN Topics T ON F.ForumId = T.ForumId
WHERE
	T.TopicId = @TopicId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPForumsUpdateLastTopic]
	@ForumId int
AS

UPDATE F
SET
	F.ForumTopicCount = F.ForumTopicCount + 1
FROM
	Forums F
WHERE
	F.ForumId = @ForumId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPForumsInsert]
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
)
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPForumsUpdate]
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
	ForumShortName = @ForumShortName


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPForumsGetUsedShortNames]
(
	@ForumShortName varchar(32), 
	@SearchShortName varchar(32)
)
AS

DECLARE @CurrentValue varchar(32)
SELECT 
	@CurrentValue = ForumShortName
FROM 
	Forums
WHERE
	ForumShortName = @ForumShortName
	

IF @CurrentValue IS NULL
	SELECT NULL As ForumShortName
ELSE
	SELECT 
		ForumShortName
	FROM
		Forums
	WHERE
		ForumShortName LIKE @SearchShortName + '%'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTagsInsert]
	@Tags varchar(256),
	@TopicId int,
	@PreviousTags varchar(256)=NULL
AS

IF NOT @PreviousTags IS NULL
	BEGIN
	DELETE FROM Tags
	WHERE
		Tag IN (SELECT part FROM dbo.Split(@PreviousTags, ' '))
		AND
		TopicId = @TopicId
	END

INSERT INTO Tags
(Tag,TopicId)
SELECT part, @TopicId FROM dbo.Split(@Tags, ' ')
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTagsGetMostViewed]
	@ForumId int=2
	,@Top bigint=5
AS
SELECT
	Tag, 
	TagViews, 
	(TagViews*100.00)/SUM(TagViews) OVER() AS Weight
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
	GROUP BY
		Tags.Tag
	ORDER BY SUM(T.TopicViews) desc
	) T
ORDER BY Tag
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPUsersGetAll]
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
ORDER BY 
	U.UserName

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPUsersGetByName]
	@UserName varchar(50)='Jorge'	
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
	U.UserName LIKE '%' + @UserName +  '%'
	AND
	U.Active = 1
ORDER BY 
	U.UserName


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[SPUsersInsertFromFacebook]
	@FacebookUserId	bigint
	,@FacebookFirstName	varchar(255)
	,@FacebookLastName	varchar(255)
	,@FacebookProfileUrl	varchar(1024)
	,@FacebookAbout	varchar(max)
	,@FacebookBirthDate	datetime
	,@FacebookLocale	varchar(5)
	,@FacebookPic	varchar(1024)
	,@FacebookTimeZone	decimal(9,2)
	,@FacebookWebsite	varchar(255)
	,@UserGuid char(32)
AS
--Creates a user from user data
--Inserts into users and usersfacebook
--returns a select with the userid

--If it is the first active user -> make it an admin
DECLARE @UserGroupId smallint, @UserCount int
SELECT @UserCount=COUNT(UserId) FROM Users WHERE Active = 1
IF ISNULL(@UserCount, 0) > 0
	SELECT @UserGroupId = 1
ELSE
	SELECT @UserGroupId = MAX(UserGroupId) FROM UsersGroups

BEGIN TRY
	DECLARE @UserId int
	BEGIN TRANSACTION
	INSERT INTO Users
	(
	UserName
	,UserProfile
	,UserBirthDate
	,UserWebsite
	,UserGuid
	,UserTimezone
	,UserPhoto
	,UserRegistrationDate
	,UserGroupId
	,Active
	,UserExternalProfileUrl
	)
	VALUES
	(
	@FacebookFirstName	+ ' ' + @FacebookLastName	
	,@FacebookAbout	
	,@FacebookBirthDate
	,@FacebookWebsite	
	,@UserGuid
	,@FacebookTimeZone
	,@FacebookPic
	,GETUTCDATE()
	,@UserGroupId
	,1--Active	
	,@FacebookProfileUrl
	)
	
	select @UserId = @@IDENTITY
	INSERT INTO UsersFacebook
	(
		UserId
		,FacebookUserId	
		,FacebookFirstName	
		,FacebookLastName	
		,FacebookProfileUrl	
		,FacebookAbout	
		,FacebookBirthDate	
		,FacebookLocale	
		,FacebookPic	
		,FacebookTimeZone	
		,FacebookWebsite	
	)
	VALUES
	(
		@UserId
		,@FacebookUserId	
		,@FacebookFirstName	
		,@FacebookLastName	
		,@FacebookProfileUrl	
		,@FacebookAbout	
		,@FacebookBirthDate	
		,@FacebookLocale	
		,@FacebookPic	
		,@FacebookTimeZone	
		,@FacebookWebsite	
	)
	
	COMMIT
	
	SELECT 
		U.UserId
		,U.UserName
		,U.UserGroupId
		,U.UserGuid
		,U.UserTimeZone
	FROM
		Users U
	WHERE
		U.UserId = @UserId

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

  -- Raise an error with the details of the exception
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		 @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)

END CATCH





GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPUsersGroupsGet]
	@UserGroupId smallint=1
AS
SELECT 
	UserGroupId
	,UserGroupName
FROM
	UsersGroups
WHERE
	UserGroupId = @UserGroupId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPUsersGet]
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
	,UG.UserGroupId
	,UG.UserGroupName
FROM
	Users U
	INNER JOIN UsersGroups UG ON UG.UserGroupId = U.UserGroupId
WHERE
	U.UserId = @UserId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPUsersPromote]
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
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPUsersDemote]
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
		UserId = @UserId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTopicsClose]
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
		TopicId = @TopicId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTopicsOpen]
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
		TopicId = @TopicId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPTopicsDelete]
	@TopicId int
	,@UserId int
	,@Ip varchar(15)
AS
/*
SETS THE TOPIC ACTIVE=0
*/
	UPDATE Topics
	SET
		Active = 0
		,TopicLastEditDate = GETUTCDATE()
		,TopicLastEditUser = @UserId
		,TopicLastEditIp = @Ip
	WHERE
		TopicId = @TopicId

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTopicsAddVisit]
	@TopicId int=2
AS
UPDATE Topics
SET
	TopicViews = TopicViews+1
WHERE
	TopicId = @TopicId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SPTemplatesInsert]
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

SELECT @TemplateId = @@IDENTITY


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPTemplatesDelete]
	@TemplateId int
AS
DELETE FROM Templates WHERE TemplateId = @TemplateId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPUsersGetByFacebookId]
	@uid bigint
AS
SELECT 
	U.UserId
	,U.UserName
	,U.UserGroupId
	,U.UserGuid
	,U.UserTimeZone
	,U.UserExternalProfileUrl
FROM
	UsersFacebook UF
	INNER JOIN Users U ON U.UserId = UF.UserId
WHERE
	FacebookUserId = @uid
	AND
	U.Active = 1

GO
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
FROM
	UsersFacebook UF
	INNER JOIN Users U ON U.UserId = UF.UserId
WHERE
	U.Active = 1
ORDER BY
	U.UserGroupId DESC
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPUsersDelete]
	@UserId int
AS
UPDATE Users
SET	
	Active = 0
WHERE 
	UserId = @UserId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPMessagesDelete]
	@MessageId int
	,@UserId int
AS
UPDATE Messages
SET
	Active = 0
	,MessageLastEditDate = GETUTCDATE()
	,MessageLastEditUser = @UserId
WHERE
	MessageId = @MessageId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPForumsGetByCategory]
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
	F.ForumOrder
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPForumsCategoriesGetAll]
AS
SELECT 
	CategoryId
	,CategoryName
	,CategoryOrder
FROM
	ForumsCategories
ORDER BY
	CategoryOrder
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTopicsMove]
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

END CATCH
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[SPTopicsInsert]
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
	)

	SELECT @TopicId = @@IDENTITY

	--Add tags
	exec dbo.[SPTagsInsert] @Tags=@TopicTags, @TopicId=@TopicId

	--Update forums
	exec dbo.[SPForumsUpdateLastTopic] @ForumId=@ForumId
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

END CATCH




GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPTopicsGetByRelated]
	@Tag1 varchar(50)='problem'
	,@Tag2 varchar(50)='installation'
	,@Tag3 varchar(50)='copy'
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
	1 desc, Topics.TopicViews desc


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTopicsGetByTag]
	@Tag varchar(50)='forum',
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
	Tags.Tag LIKE @Tag + '%'
	AND
	T.ForumId = @ForumId
ORDER BY TopicOrder DESC,TopicViews DESC


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTopicsGetByForumLatest]
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
	RowNumber BETWEEN @StartIndex+1 AND @StartIndex + @Length

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPTopicsGetLatest]
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
	
	ORDER BY T.TopicId desc

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTopicsGet]
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
	T.TopicId = @TopicId
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPTopicsGetByForumUnanswered]
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
	TopicViews DESC

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPTopicsGetByForum]
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
	RowNumber BETWEEN @StartIndex+1 AND @StartIndex + @Length


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPMessagesGetByTopic]
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
	M.TopicId = @TopicId


GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SPMessagesGetByTopicFrom]
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
	RowNumber <= @Amount




GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SPMessagesGetByTopicUpTo]
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
	M.MessageId <= @LastMsg



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SPMessagesGetByTopicLatest]
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
	TopicId, MessageId DESC




GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[SPMessagesInsert]
	@TopicId int
	,@MessageBody varchar(max)
	,@UserId int
	,@MessageId int OUTPUT
	,@Ip varchar(15)
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

END CATCH






GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SPTopicsUpdate]
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

END CATCH



