SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPPageContentsDelete]
	@PageContentShortName varchar(128)
AS
DELETE FROM PageContents 
WHERE
	PageContentShortName = @PageContentShortName


GO
