SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTopicsGetByUser]
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
ORDER BY T.TopicId desc



GO
