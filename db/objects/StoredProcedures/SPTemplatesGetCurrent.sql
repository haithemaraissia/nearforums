SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPTemplatesGetCurrent]

AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
FROM
	Templates
WHERE
	TemplateIsCurrent = 1

GO
