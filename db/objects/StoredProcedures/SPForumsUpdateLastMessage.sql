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
	Topics T
	INNER JOIN Forums F ON F.ForumId = T.ForumId
WHERE
  T.TopicId = @TopicId;

GO
