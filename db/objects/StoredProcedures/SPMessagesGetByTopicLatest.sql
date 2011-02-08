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
