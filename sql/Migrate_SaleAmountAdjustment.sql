-- Tutar düzeltmesi (negatif DiscountFixedAmount) net toplama eklenir.
-- Önceki fn_Sale_NetTotal yalnızca pozitif tutar indirimini düşüyordu;
-- eksi düzeltme kayıtlı kalsa da TotalAmount yüzde indiriminde kalıyordu.
--
-- Örnek: ara toplam 1910, %30 = 573, düzeltme -63 → net 1400.

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [dbo].[fn_Sale_NetTotal]
(
    @Subtotal DECIMAL(18, 2),
    @DiscountPercent DECIMAL(5, 2),
    @DiscountFixedAmount DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    IF @Subtotal IS NULL OR @Subtotal <= 0
        RETURN 0;

    DECLARE @PercentAmt DECIMAL(18, 2) = 0;
    DECLARE @AfterPercent DECIMAL(18, 2) = @Subtotal;
    DECLARE @FixedAmt DECIMAL(18, 2) = 0;

    IF @DiscountPercent > 0
        SET @PercentAmt = ROUND(@Subtotal * @DiscountPercent / 100.0, 2);

    SET @AfterPercent = @Subtotal - @PercentAmt;
    IF @AfterPercent < 0
        SET @AfterPercent = 0;

    IF @DiscountFixedAmount > 0
    BEGIN
        SET @FixedAmt = ROUND(@DiscountFixedAmount, 2);
        IF @FixedAmt > @AfterPercent
            SET @FixedAmt = @AfterPercent;
    END
    ELSE IF @DiscountFixedAmount < 0
    BEGIN
        SET @FixedAmt = ROUND(@DiscountFixedAmount, 2);
        DECLARE @MaxAddBack DECIMAL(18, 2) = @Subtotal - @AfterPercent;
        IF @FixedAmt < -@MaxAddBack
            SET @FixedAmt = -@MaxAddBack;
    END

    RETURN @AfterPercent - @FixedAmt;
END
GO
