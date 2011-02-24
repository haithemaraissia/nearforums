SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SPMessagesFlag
(
	@TopicId int=1
	,@MessageId int=1
	,@Ip varchar(15)='127.0.0.1'
)
AS
IF NOT EXISTS (SELECT * FROM Flags WHERE TopicId=@TopicId AND IP=@Ip AND (MessageId=@MessageId OR (@MessageId IS NULL AND MessageId IS NULL)))
	BEGIN
	INSERT INTO Flags
	(TopicId, MessageId, Ip, FlagDate)
	VALUES
	(@TopicId, @MessageId, @Ip, GETUTCDATE())
	END

GO
