SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PageContents](
	[PageContentId] [int] IDENTITY(1,1) NOT NULL,
	[PageContentTitle] [varchar](128) NOT NULL,
	[PageContentBody] [varchar](max) NOT NULL,
	[PageContentShortName] [varchar](128) NOT NULL,
	[PageContentEditDate] [datetime] NOT NULL,
 CONSTRAINT [PK_PageContents] PRIMARY KEY CLUSTERED 
(
	[PageContentId] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
