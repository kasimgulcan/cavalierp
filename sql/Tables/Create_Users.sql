-- CSM.Stok — Users (mobil auth + üyelik onayı)

IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
    DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users
(
    UserId        INT            IDENTITY(1, 1) NOT NULL,
    Email         NVARCHAR(256)  NOT NULL,
    PasswordHash  VARBINARY(64)  NOT NULL,
    Status        NVARCHAR(20)   NOT NULL CONSTRAINT DF_Users_Status DEFAULT (N'Pending'),
    Role          NVARCHAR(20)   NOT NULL CONSTRAINT DF_Users_Role DEFAULT (N'Member'),
    CreatedAt     DATETIME       NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (GETDATE()),
    UpdatedAt     DATETIME       NULL,
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT CK_Users_Status CHECK (Status IN (N'Pending', N'Approved', N'Rejected', N'Deleted')),
    CONSTRAINT CK_Users_Role CHECK (Role IN (N'Member', N'Staff'))
);
GO

CREATE NONCLUSTERED INDEX IX_Users_Status
    ON dbo.Users (Status)
    INCLUDE (Email, CreatedAt);
GO

IF OBJECT_ID(N'dbo.RefreshTokens', N'U') IS NOT NULL
    DROP TABLE dbo.RefreshTokens;
GO

CREATE TABLE dbo.RefreshTokens
(
    RefreshTokenId INT            IDENTITY(1, 1) NOT NULL,
    UserId         INT            NOT NULL,
    Token          NVARCHAR(512)  NOT NULL,
    ExpiresAt      DATETIME       NOT NULL,
    CreatedAt      DATETIME       NOT NULL CONSTRAINT DF_RefreshTokens_CreatedAt DEFAULT (GETDATE()),
    CONSTRAINT PK_RefreshTokens PRIMARY KEY CLUSTERED (RefreshTokenId),
    CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId)
        REFERENCES dbo.Users (UserId),
    CONSTRAINT UQ_RefreshTokens_Token UNIQUE (Token)
);
GO

CREATE NONCLUSTERED INDEX IX_RefreshTokens_UserId
    ON dbo.RefreshTokens (UserId, ExpiresAt DESC);
GO
