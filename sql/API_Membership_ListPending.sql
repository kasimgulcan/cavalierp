CREATE OR ALTER PROCEDURE dbo.API_Membership_ListPending
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Users table
    SELECT u.UserId, u.Email, u.Status, u.CreatedAt
    FROM dbo.Users u
    WHERE u.Status = 'Pending'
    ORDER BY u.CreatedAt;
END
GO
