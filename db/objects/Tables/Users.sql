SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](50) NOT NULL,
	[UserProfile] [varchar](max) NULL,
	[UserSignature] [varchar](max) NULL,
	[UserGroupId] [smallint] NOT NULL,
	[Active] [bit] NOT NULL,
	[UserBirthDate] [datetime] NULL,
	[UserWebsite] [varchar](255) NULL,
	[UserGuid] [char](32) NOT NULL,
	[UserTimezone] [decimal](9, 2) NOT NULL,
	[UserEmail] [varchar](100) NULL,
	[UserEmailPolicy] [int] NULL,
	[UserPhoto] [varchar](1024) NULL,
	[UserRegistrationDate] [datetime] NOT NULL,
	[UserExternalProfileUrl] [varchar](255) NULL,
	[UserProvider] [varchar](32) NOT NULL,
	[UserProviderId] [varchar](64) NOT NULL,
	[UserProviderLastCall] [datetime] NOT NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE NONCLUSTERED INDEX [IX_Users] ON [dbo].[Users] 
(
	[UserProvider] ASC,
	[UserProviderId] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_UsersGroups] FOREIGN KEY([UserGroupId])
REFERENCES [dbo].[UsersGroups] ([UserGroupId])
GO
