SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTopicsSubscriptionsInsert]
	@TopicId int
	,@UserId int
AS
IF NOT EXISTS (SELECT TopicId FROM TopicsSubscriptions WHERE TopicId = @TopicId AND UserID = @UserId)
BEGIN
	INSERT INTO TopicsSubscriptions
	(TopicId, UserId)
	VALUES
	(@TopicId, @UserId)
END
GO
