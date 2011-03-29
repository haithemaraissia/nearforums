SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPPageContentsUpdate]
	@PageContentShortName varchar(128)
	,@PageContentTitle varchar(128)
	,@PageContentBody varchar(max)
AS
UPDATE PageContents 
SET
	PageContentTitle = @PageContentTitle
	,PageContentBody = @PageContentBody
	,PageContentEditDate = GETUTCDATE()
WHERE
	PageContentShortName = @PageContentShortName

GO
