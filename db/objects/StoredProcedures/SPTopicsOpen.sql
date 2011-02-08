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
