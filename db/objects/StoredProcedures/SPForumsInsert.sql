SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SPForumsInsert
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
