SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SPTopicsUpdateLastMessageId
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
