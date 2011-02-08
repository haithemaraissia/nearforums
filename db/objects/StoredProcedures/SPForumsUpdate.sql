SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPForumsUpdate]
(
	@ForumShortName varchar(32)
	,@ForumName varchar(255)
	,@ForumDescription varchar(max)
	,@CategoryId int
	,@UserId int
)
AS
UPDATE Forums
SET
	ForumName = @ForumName
	,ForumDescription = @ForumDescription 
	,CategoryId = @CategoryId
	,ForumLastEditDate = GETUTCDATE()
	,ForumLastEditUser = @UserId
WHERE
	ForumShortName = @ForumShortName


GO
