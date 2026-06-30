CREATE OR ALTER PROCEDURE dbo.API_Auth_GetProfile
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Email, u.Status, u.Role, u.CreatedAt
    FROM dbo.Users u
    WHERE u.UserId = @UserId;
END
GO
