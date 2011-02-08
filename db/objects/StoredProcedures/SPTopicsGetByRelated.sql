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
