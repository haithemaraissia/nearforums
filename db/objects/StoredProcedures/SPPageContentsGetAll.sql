SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPPageContentsGetAll]
	
AS
SELECT
	PageContentId
	,PageContentTitle
	,PageContentBody
	,PageContentShortName
FROM
	dbo.PageContents
ORDER BY
	PageContentTitle


GO
