SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SPPageContentsInsert]
	@PageContentShortName varchar(128)
	,@PageContentTitle varchar(128)
	,@PageContentBody varchar(max)
AS
INSERT INTO PageContents 
(
PageContentTitle
,PageContentBody
,PageContentShortName
,PageContentEditDate
)
VALUES
(
@PageContentTitle
,@PageContentBody
,@PageContentShortName
,GETUTCDATE()
)


GO
