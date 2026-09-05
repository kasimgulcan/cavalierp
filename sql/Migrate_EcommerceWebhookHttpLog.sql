-- Ecommerce webhook HTTP request/response log (01.09.2026)
-- StockWebhookInbound / StockWebhookOutbound üzerine ham JSON.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.StockWebhookInbound', 'RequestJson') IS NULL
    ALTER TABLE dbo.StockWebhookInbound ADD RequestJson NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.StockWebhookInbound', 'ResponseJson') IS NULL
    ALTER TABLE dbo.StockWebhookInbound ADD ResponseJson NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.StockWebhookInbound', 'HttpStatus') IS NULL
    ALTER TABLE dbo.StockWebhookInbound ADD HttpStatus INT NULL;
GO

IF COL_LENGTH('dbo.StockWebhookOutbound', 'RequestJson') IS NULL
    ALTER TABLE dbo.StockWebhookOutbound ADD RequestJson NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.StockWebhookOutbound', 'ResponseJson') IS NULL
    ALTER TABLE dbo.StockWebhookOutbound ADD ResponseJson NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.StockWebhookOutbound', 'HttpStatus') IS NULL
    ALTER TABLE dbo.StockWebhookOutbound ADD HttpStatus INT NULL;
GO
IF COL_LENGTH('dbo.StockWebhookOutbound', 'RequestUrl') IS NULL
    ALTER TABLE dbo.StockWebhookOutbound ADD RequestUrl NVARCHAR(500) NULL;
GO

CREATE OR ALTER PROCEDURE [dbo].[API_WebHook_InboundSaveHttp]
    @EventId UNIQUEIDENTIFIER,
    @RequestJson NVARCHAR(MAX),
    @HttpStatus INT,
    @ResponseJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockWebhookInbound
    SET RequestJson = @RequestJson,
        ResponseJson = @ResponseJson,
        HttpStatus = @HttpStatus
    WHERE EventId = @EventId;

    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.StockWebhookInbound (
            EventId, EventType, SkuCode, Quantity, OnHand, ResultCode, ErrorMessage,
            RequestJson, ResponseJson, HttpStatus
        )
        VALUES (
            @EventId, N'', N'', 0, NULL, @HttpStatus, NULL,
            @RequestJson, @ResponseJson, @HttpStatus
        );
    END
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_WebHook_InboundListHttp]
    @Take INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Take)
        InboundId AS Id,
        EventId,
        EventType,
        SkuCode,
        RequestJson,
        HttpStatus,
        ResponseJson,
        ReceivedAt AS [At]
    FROM dbo.StockWebhookInbound
    ORDER BY InboundId DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_WebHook_OutboundListHttp]
    @Take INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Take)
        OutboundId AS Id,
        EventId,
        EventType,
        SkuCode,
        RequestUrl,
        RequestJson,
        HttpStatus,
        ResponseJson,
        ISNULL(SentAt, CreatedAt) AS [At]
    FROM dbo.StockWebhookOutbound
    ORDER BY OutboundId DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_WebHook_OutboundMarkSent]
    @OutboundId BIGINT,
    @RequestUrl NVARCHAR(500) = NULL,
    @RequestJson NVARCHAR(MAX) = NULL,
    @HttpStatus INT = NULL,
    @ResponseJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.StockWebhookOutbound
    SET Status = N'Sent',
        SentAt = SYSUTCDATETIME(),
        LastError = NULL,
        RequestUrl = COALESCE(@RequestUrl, RequestUrl),
        RequestJson = COALESCE(@RequestJson, RequestJson),
        HttpStatus = COALESCE(@HttpStatus, HttpStatus),
        ResponseJson = COALESCE(@ResponseJson, ResponseJson)
    WHERE OutboundId = @OutboundId;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[API_WebHook_OutboundMarkAttempt]
    @OutboundId BIGINT,
    @Error NVARCHAR(4000),
    @Failed BIT,
    @RequestUrl NVARCHAR(500) = NULL,
    @RequestJson NVARCHAR(MAX) = NULL,
    @HttpStatus INT = NULL,
    @ResponseJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.StockWebhookOutbound
    SET Attempts = Attempts + 1,
        LastError = @Error,
        Status = CASE WHEN @Failed = 1 THEN N'Failed' ELSE Status END,
        RequestUrl = COALESCE(@RequestUrl, RequestUrl),
        RequestJson = COALESCE(@RequestJson, RequestJson),
        HttpStatus = COALESCE(@HttpStatus, HttpStatus),
        ResponseJson = COALESCE(@ResponseJson, ResponseJson)
    WHERE OutboundId = @OutboundId;
END
GO
