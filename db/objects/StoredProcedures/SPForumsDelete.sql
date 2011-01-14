SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SPForumsDelete
	@ForumShortName varchar(32)
AS

UPDATE Forums
SET
	Active = 0
WHERE
	ForumShortName = @ForumShortName
GO
