CREATE OR ALTER PROCEDURE dbo.API_Auth_DeleteAccount
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: soft-delete vs hard-delete per existing schema
    UPDATE dbo.Users
    SET Status = 'Deleted', Email = CONCAT('deleted_', @UserId, '_', Email)
    WHERE UserId = @UserId AND Status <> 'Deleted';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
