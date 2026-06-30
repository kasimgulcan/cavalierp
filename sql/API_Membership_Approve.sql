CREATE OR ALTER PROCEDURE dbo.API_Membership_Approve
    @UserId INT,
    @Role NVARCHAR(20) = N'Member'
AS
BEGIN
    SET NOCOUNT ON;
    IF @Role NOT IN (N'Member', N'Staff')
        SET @Role = N'Member';

    UPDATE dbo.Users
    SET Status = N'Approved', Role = @Role
    WHERE UserId = @UserId AND Status = N'Pending';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
