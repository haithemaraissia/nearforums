SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPPageContentsGetUsedShortNames]
(
	@PageContentShortName varchar(32), 
	@SearchShortName varchar(32)
)
AS
/*
	Gets used short names for PageContents
	returns:
		IF NOT USED SHORTNAME: empty result set
		IF USED SHORTNAME: resultset with amount of rows used
*/
DECLARE @CurrentValue varchar(32)
SELECT 
	@CurrentValue = PageContentShortName
FROM 
	PageContents
WHERE
	PageContentShortName = @PageContentShortName
	

IF @CurrentValue IS NULL
	SELECT NULL As ForumShortName WHERE 1=0
ELSE
	SELECT 
		PageContentShortName
	FROM
		PageContents
	WHERE
		PageContentShortName LIKE @SearchShortName + '%'
		OR
		PageContentShortName = @PageContentShortName


GO
