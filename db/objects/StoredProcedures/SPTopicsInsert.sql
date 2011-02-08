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

END CATCH





GO
