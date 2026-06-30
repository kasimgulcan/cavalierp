CREATE OR ALTER PROCEDURE dbo.API_Membership_Reject
    @UserId INT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Users table; optional rejection reason column
    UPDATE dbo.Users
    SET Status = 'Rejected'
    WHERE UserId = @UserId AND Status = 'Pending';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
