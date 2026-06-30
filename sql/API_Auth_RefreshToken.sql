CREATE OR ALTER PROCEDURE dbo.API_Auth_RefreshToken
    @RefreshToken NVARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status
    FROM dbo.RefreshTokens rt
    INNER JOIN dbo.Users u ON u.UserId = rt.UserId
    WHERE rt.Token = @RefreshToken
      AND rt.ExpiresAt > GETDATE()
      AND u.Status <> N'Rejected';
END
GO
