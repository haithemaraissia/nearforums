SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPTemplatesGetAll]
AS
SELECT
	TemplateId
	,TemplateKey
	,TemplateDescription
	,TemplateIsCurrent
FROM
	Templates

GO
