USE [CavaliERP]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_Sale_NetTotal]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   FUNCTION [dbo].[fn_Sale_NetTotal]
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
        SET @PercentAmt = ROUND(@Subtotal * @DiscountPercent / 100.0, 0);

    SET @AfterPercent = @Subtotal - @PercentAmt;
    IF @AfterPercent < 0
        SET @AfterPercent = 0;

    IF @DiscountFixedAmount > 0
    BEGIN
        SET @FixedAmt = ROUND(@DiscountFixedAmount, 0);
        IF @FixedAmt > @AfterPercent
            SET @FixedAmt = @AfterPercent;
    END

    RETURN @AfterPercent - @FixedAmt;
END
GO
/****** Object:  UserDefinedFunction [dbo].[String.Split]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[String.Split] 
( 
    @Text VARCHAR(MAX), 
    @Delimiter VARCHAR(100), 
    @Index INT 
) 
RETURNS VARCHAR(MAX) 
AS BEGIN 
    DECLARE @A TABLE (ID INT IDENTITY, V VARCHAR(MAX)); 
    DECLARE @R VARCHAR(MAX); 
    WITH CTE AS 
    ( 
    SELECT 0 A, 1 B 
    UNION ALL 
    SELECT B, CONVERT(INT,CHARINDEX(@Delimiter, @Text, B) + LEN(@Delimiter)) 
    FROM CTE 
    WHERE B > A 
    ) 
    INSERT @A(V) 
    SELECT SUBSTRING(@Text,A,CASE WHEN B > LEN(@Delimiter) THEN B-A-LEN(@Delimiter) ELSE LEN(@Text) - A + 1 END) VALUE       
    FROM CTE WHERE A >0 
 
    SELECT      @R 
    =           V 
    FROM        @A 
    WHERE       ID = @Index + 1 
    RETURN      @R 
END 
GO
/****** Object:  Table [dbo].[Article]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Article](
	[ArticleId] [int] IDENTITY(1,1) NOT NULL,
	[StyleId] [int] NULL,
	[YearId] [int] NULL,
	[SeasonId] [int] NULL,
	[MainFabricId] [int] NULL,
	[FabricMaterialId] [int] NULL,
 CONSTRAINT [PK_KG_Article] PRIMARY KEY CLUSTERED 
(
	[ArticleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ModelReference]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ModelReference](
	[ModelReferenceId] [int] IDENTITY(1,1) NOT NULL,
	[ModelReference] [nvarchar](20) NULL,
	[ModelName] [nvarchar](100) NOT NULL,
	[ModelGender] [nvarchar](20) NULL,
	[ModelAge] [int] NULL,
	[ModelOrigin] [nvarchar](100) NULL,
	[ModelAgency] [nvarchar](100) NULL,
	[Caption] [nvarchar](200) NULL,
	[HeightCm] [int] NULL,
	[WeightKg] [int] NULL,
	[ChestCm] [int] NULL,
	[WaistCm] [int] NULL,
	[HipsCm] [int] NULL,
	[ShoeSizeEU] [int] NULL,
	[WebSiteCode] [nvarchar](200) NULL,
 CONSTRAINT [PK_Models] PRIMARY KEY CLUSTERED 
(
	[ModelReferenceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Variant]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Variant](
	[VariantId] [int] IDENTITY(1,1) NOT NULL,
	[ArticleId] [int] NULL,
	[MainColorId] [int] NULL,
	[SecondaryColorId] [int] NULL,
	[ModelReferenceId] [int] NULL,
	[WebImageURL] [varchar](500) NULL,
	[NewIn] [bit] NULL,
	[Bestsellers] [bit] NULL,
	[ShopTheLook] [bit] NULL,
	[Competition] [bit] NULL,
	[Outlet] [bit] NULL,
	[TBFXSanMarco] [bit] NULL,
	[TheAfterCollection] [bit] NULL,
	[MainPhoto] [varchar](500) NULL,
	[Photo2] [varchar](500) NULL,
	[Photo3] [varchar](500) NULL,
	[Photo4] [varchar](500) NULL,
	[Photo5] [varchar](500) NULL,
	[Photo6] [varchar](500) NULL,
	[Video] [varchar](500) NULL,
	[ExtraMedia] [varchar](500) NULL,
	[AlsoInThePhoto1] [int] NULL,
	[AlsoInThePhoto2] [int] NULL,
	[AlsoInThePhoto3] [int] NULL,
	[AlsoInThePhoto4] [int] NULL,
	[AlsoInThePhoto5] [int] NULL,
	[RelatedProducts1] [int] NULL,
	[RelatedProducts2] [int] NULL,
	[RelatedProducts3] [int] NULL,
	[RelatedProducts4] [int] NULL,
	[RelatedProducts5] [int] NULL,
	[WebSiteVariant] [varchar](500) NULL,
	[WebSiteAdditionalCategories] [varchar](500) NULL,
	[Publish] [bit] NULL,
 CONSTRAINT [PK_KG_Variant] PRIMARY KEY CLUSTERED 
(
	[VariantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MainCategory]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MainCategory](
	[MainCategoryId] [int] IDENTITY(1,1) NOT NULL,
	[MainCategoryName] [nvarchar](100) NOT NULL,
	[MainCategoryCode] [nvarchar](10) NOT NULL,
	[WebSiteCode] [int] NULL,
 CONSTRAINT [PK_MainCategory] PRIMARY KEY CLUSTERED 
(
	[MainCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_MainCategory_Code] UNIQUE NONCLUSTERED 
(
	[MainCategoryCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WebCategory]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebCategory](
	[WebCategoryId] [int] IDENTITY(1,1) NOT NULL,
	[WebCategoryName] [nvarchar](100) NOT NULL,
	[WebCategoryCode] [nvarchar](20) NOT NULL,
	[WebSiteCode] [int] NULL,
 CONSTRAINT [PK_WebCategory] PRIMARY KEY CLUSTERED 
(
	[WebCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_WebCategory_Code] UNIQUE NONCLUSTERED 
(
	[WebCategoryCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ProductGroup]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductGroup](
	[ProductGroupId] [int] IDENTITY(1,1) NOT NULL,
	[ProductGroupName] [nvarchar](150) NOT NULL,
	[ProductGroupCode] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_ProductGroup] PRIMARY KEY CLUSTERED 
(
	[ProductGroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_ProductGroup_Code] UNIQUE NONCLUSTERED 
(
	[ProductGroupCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ProductGroupWeb]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductGroupWeb](
	[ProductGroupWebId] [int] IDENTITY(1,1) NOT NULL,
	[ProductGroupId] [int] NULL,
	[WebCategoryId] [int] NULL,
	[WebSiteCode] [int] NULL,
 CONSTRAINT [PK_ProductGroupWeb] PRIMARY KEY CLUSTERED 
(
	[ProductGroupWebId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TypeGender]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TypeGender](
	[TypeGenderId] [int] IDENTITY(1,1) NOT NULL,
	[TypeGenderName] [nvarchar](100) NOT NULL,
	[TypeGenderCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_TypeGender] PRIMARY KEY CLUSTERED 
(
	[TypeGenderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_TypeGender_Code] UNIQUE NONCLUSTERED 
(
	[TypeGenderCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ProductCategoryWeb]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductCategoryWeb](
	[ProductCategoryWebId] [int] IDENTITY(1,1) NOT NULL,
	[ProductCategoryId] [int] NULL,
	[WebCategoryId] [int] NULL,
	[WebSiteCode] [int] NULL,
	[WebSiteAbbr] [varchar](50) NULL,
 CONSTRAINT [PK_ProductCategoryWeb] PRIMARY KEY CLUSTERED 
(
	[ProductCategoryWebId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ProductCategory]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductCategory](
	[ProductCategoryId] [int] IDENTITY(1,1) NOT NULL,
	[ProductCategoryName] [nvarchar](150) NOT NULL,
	[ProductCategoryCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_ProductCategory] PRIMARY KEY CLUSTERED 
(
	[ProductCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_ProductCategory_Code] UNIQUE NONCLUSTERED 
(
	[ProductCategoryCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FabricMaterial]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FabricMaterial](
	[FabricMaterialId] [int] IDENTITY(1,1) NOT NULL,
	[FabricMaterialCode]  AS (right('000'+rtrim([FabricMaterialId]),(4))),
	[FabricMaterialName] [nvarchar](200) NOT NULL,
	[SupplierFabricMaterialName] [nvarchar](200) NULL,
	[FabricCategory] [nvarchar](100) NULL,
	[FabricType] [nvarchar](100) NULL,
	[Composition] [nvarchar](500) NULL,
	[CareLabel] [nvarchar](500) NULL,
	[PricePerMt] [nvarchar](50) NULL,
	[Aciklama] [nvarchar](500) NULL,
	[SupplierName] [nvarchar](200) NULL,
	[Origin] [nvarchar](50) NULL,
	[YarnCount] [nvarchar](100) NULL,
	[Construction] [nvarchar](200) NULL,
	[Finish] [nvarchar](200) NULL,
	[Width] [nvarchar](50) NULL,
	[WeightPerM2] [int] NULL,
 CONSTRAINT [PK_FabricMaterial] PRIMARY KEY CLUSTERED 
(
	[FabricMaterialId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Season]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Season](
	[SeasonId] [int] IDENTITY(1,1) NOT NULL,
	[SeasonCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_Season] PRIMARY KEY CLUSTERED 
(
	[SeasonId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Season_SeasonCode] UNIQUE NONCLUSTERED 
(
	[SeasonCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MainFabric]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MainFabric](
	[MainFabricId] [int] IDENTITY(1,1) NOT NULL,
	[MainFabricName] [nvarchar](150) NOT NULL,
	[MainFabricCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_MainFabricMaterial] PRIMARY KEY CLUSTERED 
(
	[MainFabricId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_MainFabricMaterial_Code] UNIQUE NONCLUSTERED 
(
	[MainFabricCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Color]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Color](
	[ColorId] [int] IDENTITY(1,1) NOT NULL,
	[ColorName] [nvarchar](100) NOT NULL,
	[ColorCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_Color] PRIMARY KEY CLUSTERED 
(
	[ColorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Color_Code] UNIQUE NONCLUSTERED 
(
	[ColorCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SizeChart]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SizeChart](
	[SizeChartId] [int] IDENTITY(1,1) NOT NULL,
	[SizeChartName] [nvarchar](150) NOT NULL,
	[SizeChartCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_SizeTypex] PRIMARY KEY CLUSTERED 
(
	[SizeChartId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_SizeType_Codex] UNIQUE NONCLUSTERED 
(
	[SizeChartCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Style]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Style](
	[StyleId] [int] IDENTITY(1,1) NOT NULL,
	[NameCategoryId] [int] NULL,
	[StyleName] [nvarchar](500) NULL,
	[ProductName] [nvarchar](500) NULL,
	[MainCategoryId] [int] NULL,
	[WebCategoryId] [int] NULL,
	[ProductGroupId] [int] NULL,
	[TypeGenderId] [int] NULL,
	[ProductCategoryId] [int] NULL,
	[SizeChartId] [int] NULL,
	[SizeSetId] [int] NULL,
	[ProductDescription] [nvarchar](2500) NULL,
	[ProductFeatures] [nvarchar](2500) NULL,
	[CareInstructions] [nvarchar](2500) NULL,
	[UrunAdi] [nvarchar](2500) NULL,
	[UrunAciklamasi] [nvarchar](2500) NULL,
	[UrunOzellikleri] [nvarchar](2500) NULL,
	[YikamaTalimatlari] [nvarchar](2500) NULL,
	[NomeDelProdotto] [nvarchar](2500) NULL,
	[DescrizioneDelProdotto] [nvarchar](2500) NULL,
	[CaratteristicheDelProdotto] [nvarchar](2500) NULL,
	[IstruzioniPerLaCura] [nvarchar](2500) NULL,
	[Produktname] [nvarchar](2500) NULL,
	[Produktbeschreibung] [nvarchar](2500) NULL,
	[Produktmerkmale] [nvarchar](2500) NULL,
	[Pflegehinweise] [nvarchar](2500) NULL,
	[PriceTL] [decimal](18, 2) NULL,
	[PriceEUR] [decimal](18, 2) NULL,
	[PriceUSD] [decimal](18, 2) NULL,
	[NewID] [int] NULL,
	[MadeInItalyLogo] [bit] NULL,
 CONSTRAINT [PK_Style_1] PRIMARY KEY CLUSTERED 
(
	[StyleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_StyleName] UNIQUE NONCLUSTERED 
(
	[StyleName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Product]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW [dbo].[V_Product]
AS
SELECT
     s.StyleId
    ,s.ProductName
    ,a.ArticleId
    ,v.VariantId
    ,a.MainFabricId
    ,a.FabricMaterialId
    ,ProductId = v.VariantId
    ,ProductCode =
          mcat.MainCategoryCode + '.'
        + pg.ProductGroupCode
        + tg.TypeGenderCode + '_'
        + pc.ProductCategoryCode
        + FORMAT(a.ArticleId, '0000') + '_'
        + mf.MainFabricCode
        + fm.FabricMaterialCode
        + mc.ColorCode
        + sc.ColorCode
    ,mcat.MainCategoryName
    ,pg.ProductGroupName
    ,tg.TypeGenderName
    ,pc.ProductCategoryName
    ,s.StyleName
    ,StyleCode = REPLACE(s.StyleName, '-', '')
    ,sea.SeasonCode
    ,mf.MainFabricName
    ,mf.MainFabricCode
    ,fm.FabricMaterialName
    ,fm.FabricMaterialCode
    ,mcat.MainCategoryCode
    ,pg.ProductGroupCode
    ,tg.TypeGenderCode
    ,pc.ProductCategoryCode
    ,MainColorCode = mc.ColorCode
    ,MainColorName = mc.ColorName
    ,SecondaryColorCode = sc.ColorCode
    ,SecondaryColorName = sc.ColorName
    ,ArticleCode =
          sea.SeasonCode
        + mf.MainFabricCode
        + fm.FabricMaterialCode
    ,FullArticleCode =
          REPLACE(s.StyleName, '-', '') + '_'
        + sea.SeasonCode
        + mf.MainFabricCode
        + fm.FabricMaterialCode
    ,VariantCode = CASE
        WHEN mc.ColorCode = sc.ColorCode THEN mc.ColorCode
        ELSE mc.ColorCode + sc.ColorCode
      END
    ,FullVariantCode =
          REPLACE(s.StyleName, '-', '') + '_'
        + sea.SeasonCode
        + mf.MainFabricCode
        + fm.FabricMaterialCode + '_'
        + CASE
            WHEN mc.ColorCode = sc.ColorCode THEN mc.ColorCode
            ELSE mc.ColorCode + sc.ColorCode
          END
    ,Color = CASE
        WHEN mc.ColorName = sc.ColorName THEN mc.ColorName
        ELSE mc.ColorName + ISNULL('/' + sc.ColorName, '')
      END
FROM Style s
LEFT JOIN MainCategory mcat ON mcat.MainCategoryId = s.MainCategoryId
LEFT JOIN WebCategory wcat ON wcat.WebCategoryId = s.WebCategoryId
LEFT JOIN ProductGroup pg ON pg.ProductGroupId = s.ProductGroupId
LEFT JOIN TypeGender tg ON tg.TypeGenderId = s.TypeGenderId
LEFT JOIN ProductCategory pc ON pc.ProductCategoryId = s.ProductCategoryId
LEFT JOIN ProductGroupWeb pgw ON pgw.ProductGroupId = pg.ProductGroupId AND pgw.WebCategoryId = wcat.WebCategoryId
LEFT JOIN ProductCategoryWeb pgc ON pgc.ProductCategoryId = pc.ProductCategoryId AND pgc.WebCategoryId = wcat.WebCategoryId
LEFT JOIN SizeChart sch ON sch.SizeChartId = s.SizeChartId
LEFT JOIN Article a ON a.StyleId = s.StyleId
LEFT JOIN MainFabric mf ON mf.MainFabricId = a.MainFabricId
LEFT JOIN Season sea ON sea.SeasonId = a.SeasonId
LEFT JOIN Variant v ON v.ArticleId = a.ArticleId
LEFT JOIN ModelReference mref ON mref.ModelReferenceId = v.ModelReferenceId
LEFT JOIN FabricMaterial fm ON fm.FabricMaterialId = a.FabricMaterialId
LEFT JOIN Color mc ON mc.ColorId = v.MainColorId
LEFT JOIN Color sc ON sc.ColorId = v.SecondaryColorId
GO
/****** Object:  Table [dbo].[Size]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Size](
	[SizeId] [int] IDENTITY(1,1) NOT NULL,
	[VariantId] [int] NULL,
	[Size] [varchar](50) NULL,
	[Barcode] [varchar](500) NULL,
	[InStockQty] [int] NULL,
 CONSTRAINT [PK_Size_1] PRIMARY KEY CLUSTERED 
(
	[SizeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_ProductSize]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW [dbo].[V_ProductSize]
AS
SELECT
     p.StyleId
    ,p.ProductName
    ,p.StyleName
    ,p.ArticleId
    ,p.VariantId
    ,si.SizeId
    ,si.Size
    ,p.MainFabricId
    ,p.FabricMaterialId
    ,p.ProductCode
    ,p.MainCategoryName
    ,p.ProductGroupName
    ,p.TypeGenderName
    ,p.ProductCategoryName
    ,p.StyleCode
    ,p.SeasonCode
    ,p.MainFabricName
    ,p.MainFabricCode
    ,p.FabricMaterialName
    ,p.FabricMaterialCode
    ,p.MainCategoryCode
    ,p.ProductGroupCode
    ,p.TypeGenderCode
    ,p.ProductCategoryCode
    ,p.MainColorCode
    ,p.MainColorName
    ,p.SecondaryColorCode
    ,p.SecondaryColorName
    ,p.ArticleCode
    ,p.FullArticleCode
    ,p.VariantCode
    ,p.Color
    ,p.FullVariantCode
    ,SKU = p.ProductCode + '_' + si.Size
    ,si.Barcode
    ,si.InStockQty
FROM dbo.V_Product p
LEFT JOIN dbo.Size si ON si.VariantId = p.VariantId
GO
/****** Object:  View [dbo].[V_FullProductCode]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   VIEW [dbo].[V_FullProductCode]
AS
SELECT
     p.VariantId
    ,p.StyleName
    ,ProductColorName = p.Color
    ,FullProductCode = p.ProductCode
FROM dbo.V_Product p
GO
/****** Object:  View [dbo].[V_SKU]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    VIEW [dbo].[V_SKU]
AS
SELECT
     [BARCODE GS1/EAN] = ps.Barcode
    ,[ART. #] = FORMAT(ps.ArticleId, '0000')
    ,[STYLE NAME] = ps.StyleName
    ,[PRODUCT NAME] = ps.ProductName
    ,[PRODUCT CODE] = ps.StyleName + ' / '
        + ps.MainFabricCode
        + ps.FabricMaterialCode
        + ps.MainColorCode
        + ps.SecondaryColorCode
    ,SIZE = ps.Size
    ,ps.SizeId
    ,[MAIN CATEGORY] = ps.MainCategoryName
    ,[WEB CATEGORY] = wcat.WebCategoryName
    ,[PRODUCT GROUP] = ps.ProductGroupName
    ,[TYPE / GENDER] = ps.TypeGenderName
    ,[PRODUCT CATEGORY] = ps.ProductCategoryName
    ,[SEASON] = ps.SeasonCode
    ,[MAIN FABRIC] = ps.MainFabricName
    ,[MAIN COLOR] = ps.MainColorName
    ,[SECONDARY COLOR] = ps.SecondaryColorName
    ,[PRODUCT COLOR NAME] = ps.Color
    ,[MODEL CODE] =
          ps.MainCategoryCode + '.'
        + ps.ProductGroupCode
        + ps.TypeGenderCode + '_'
        + ps.ProductCategoryCode
        + FORMAT(ps.ArticleId, '0000')
    ,[FABRIC + COLOR CODE] =
          ps.MainFabricCode
        + ps.FabricMaterialCode
        + ps.MainColorCode
        + ps.SecondaryColorCode
    ,[FULL PRODUCT CODE] = ps.ProductCode
    ,[SKU CODE] = ps.SKU
    ,[MAIN PHOTO] = v.MainPhoto
    ,[PHOTO 2] = v.Photo2
    ,[PHOTO 3] = v.Photo3
    ,[PHOTO 4] = v.Photo4
    ,[PHOTO 5] = v.Photo5
    ,[PHOTO 6] = v.Photo6
    ,[VIDEO] = v.Video
    ,[EXTRA MEDIA] = v.ExtraMedia
    ,[PRODUCT TITLE] = ps.StyleName + ' ' + ps.Color + ' ' + ps.ProductName + ' '
    ,[PRODUCT DESCRIPTION] = s.ProductDescription
    ,[PRODUCT FEATURES] = s.ProductFeatures
    ,[CARE INSTRUCTIONS] = s.CareInstructions
    ,[ÜRÜN ADI] = ps.StyleName + ' ' + ps.Color + ' ' + s.UrunAdi + ' '
    ,[ÜRÜN AÇIKLAMASI] = s.UrunAciklamasi
    ,[ÜRÜN ÖZELLİKLERİ] = s.UrunOzellikleri
    ,[YIKAMA TALİMATLARI] = s.YikamaTalimatlari
    ,[TITOLO DEL PRODOTTO] = ps.StyleName + ' ' + ps.Color + ' ' + s.NomeDelProdotto + ' '
    ,[DESCRIZIONE DEL PRODOTTO] = s.DescrizioneDelProdotto
    ,[CARATTERISTICHE DEL PRODOTTO] = s.CaratteristicheDelProdotto
    ,[ISTRUZIONI PER LA CURA] = s.IstruzioniPerLaCura
    ,[PRODUKTTITEL] = ps.StyleName + ' ' + ps.Color + ' ' + s.Produktname + ' '
    ,[PRODUKT BESCHREIBUNG] = s.Produktbeschreibung
    ,[PRODUKT MERKMALE] = s.Produktmerkmale
    ,[PFLEGEHINWEISE] = s.Pflegehinweise
    ,[ALSO IN THE PHOTO 1] = c1.FullProductCode
    ,[ALSO IN THE PHOTO 2] = c2.FullProductCode
    ,[ALSO IN THE PHOTO 3] = c3.FullProductCode
    ,[ALSO IN THE PHOTO 4] = c4.FullProductCode
    ,[ALSO IN THE PHOTO 5] = c5.FullProductCode
    ,[RELATED PRODUCTS 1] = v.RelatedProducts1
    ,[RELATED PRODUCTS 2] = v.RelatedProducts2
    ,[RELATED PRODUCTS 3] = v.RelatedProducts3
    ,[RELATED PRODUCTS 4] = v.RelatedProducts4
    ,[RELATED PRODUCTS 5] = v.RelatedProducts5
    ,[MAIN CATEGORY ID] = mcat.WebSiteCode
    ,[WEB CATEGORY ID] = wcat.WebSiteCode
    ,[PRODUCT GROUP ID] = pgw.WebSiteCode
    ,[TYPE/GRENDER ID] = tg.TypeGenderId
    ,[PRODUCT CATEGORY ID] = pgc.WebSiteCode
    ,[ATTRIBUTES (EX-PRODUCT CAT) ID] = NULL
    ,[NEW IN] = CASE WHEN v.NewIn = 1 THEN 75 ELSE NULL END
    ,[BESTSELLERS] = CASE WHEN v.Bestsellers = 1 THEN 204 ELSE NULL END
    ,[SHOP THE LOOK] = ''
    ,[COMPETITION] = CASE WHEN v.[Competition] = 1 THEN 21 ELSE NULL END
    ,[OUTLET] = ''
    ,[TBF X SANMARCO] = CASE WHEN v.TBFXSanMarco = 1 THEN 206 ELSE NULL END
    ,[ADDITIONAL (MANUAL) CAT.] = v.WebSiteAdditionalCategories
    ,[VARIANTS] = v.WebSiteVariant
    ,[PRICE EURO] = FORMAT(PriceEUR, 'N', 'en-US')
    ,[PRICE TL] = FORMAT(PriceTL, 'N', 'en-US')
    ,[PRICE USD] = FORMAT(PriceUSD, 'N', 'en-US')
    ,[INITIAL STOCK QTY] = NULL
    ,[SOLD QTY] = NULL
    ,[IN-STOCK QTY] = ps.InStockQty
    ,[PUBLISH] = CASE WHEN ISNULL(v.Publish, 0) = 0 THEN '0' ELSE '1' END
    ,[MODEL REFERENCE] = mref.WebSiteCode
    ,[SIZE CHART REFERENCE] = sch.SizeChartCode
    ,[MADE IN ITALY LOGO] = CASE WHEN s.MadeInItalyLogo = 1 THEN '1' ELSE '' END
    ,[UPDATE] = NULL
    ,[NOTES] = NULL
    ,s.SizeSetId
    ,ps.StyleId
    ,[THE AFTER COLLECTION] = CASE WHEN v.TheAfterCollection = 1 THEN '242' ELSE NULL END
    ,[MODEL SIZE INFO] = mref.Caption
FROM dbo.V_ProductSize ps
LEFT JOIN dbo.Style s ON s.StyleId = ps.StyleId
LEFT JOIN dbo.Article a ON a.ArticleId = ps.ArticleId
LEFT JOIN dbo.Variant v ON v.VariantId = ps.VariantId
LEFT JOIN dbo.MainCategory mcat ON mcat.MainCategoryId = s.MainCategoryId
LEFT JOIN dbo.WebCategory wcat ON wcat.WebCategoryId = s.WebCategoryId
LEFT JOIN dbo.ProductGroupWeb pgw ON pgw.ProductGroupId = s.ProductGroupId AND pgw.WebCategoryId = wcat.WebCategoryId
LEFT JOIN dbo.ProductCategoryWeb pgc ON pgc.ProductCategoryId = s.ProductCategoryId AND pgc.WebCategoryId = wcat.WebCategoryId
LEFT JOIN dbo.TypeGender tg ON tg.TypeGenderId = s.TypeGenderId
LEFT JOIN dbo.SizeChart sch ON sch.SizeChartId = s.SizeChartId
LEFT JOIN dbo.ModelReference mref ON mref.ModelReferenceId = v.ModelReferenceId
LEFT JOIN dbo.V_FullProductCode c1 ON c1.VariantId = v.AlsoInThePhoto1
LEFT JOIN dbo.V_FullProductCode c2 ON c2.VariantId = v.AlsoInThePhoto2
LEFT JOIN dbo.V_FullProductCode c3 ON c3.VariantId = v.AlsoInThePhoto3
LEFT JOIN dbo.V_FullProductCode c4 ON c4.VariantId = v.AlsoInThePhoto4
LEFT JOIN dbo.V_FullProductCode c5 ON c5.VariantId = v.AlsoInThePhoto5
GO
/****** Object:  Table [dbo].[SizeSet]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SizeSet](
	[SizeSetId] [int] IDENTITY(1,1) NOT NULL,
	[SizeSetName] [nvarchar](50) NOT NULL,
	[A01] [nvarchar](30) NULL,
	[A02] [nvarchar](30) NULL,
	[A03] [nvarchar](30) NULL,
	[A04] [nvarchar](30) NULL,
	[A05] [nvarchar](30) NULL,
	[A06] [nvarchar](30) NULL,
	[A07] [nvarchar](30) NULL,
	[A08] [nvarchar](30) NULL,
	[A09] [nvarchar](30) NULL,
 CONSTRAINT [PK_SizeSets] PRIMARY KEY CLUSTERED 
(
	[SizeSetId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_SizeSetSize]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[V_SizeSetSize]
AS
SELECT s.SizeSetId, s.SizeSetName, Pos = 1, SizeValue = s.A01 FROM SizeSet s WHERE s.A01 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 2, SizeValue = s.A02 FROM SizeSet s WHERE s.A02 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 3, SizeValue = s.A03 FROM SizeSet s WHERE s.A03 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 4, SizeValue = s.A04 FROM SizeSet s WHERE s.A04 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 5, SizeValue = s.A05 FROM SizeSet s WHERE s.A05 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 6, SizeValue = s.A06 FROM SizeSet s WHERE s.A06 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 7, SizeValue = s.A07 FROM SizeSet s WHERE s.A07 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 8, SizeValue = s.A08 FROM SizeSet s WHERE s.A08 IS NOT NULL
UNION ALL
SELECT s.SizeSetId, s.SizeSetName, Pos = 9, SizeValue = s.A09 FROM SizeSet s WHERE s.A09 IS NOT NULL;
GO
/****** Object:  Table [dbo].[StockEntries]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockEntries](
	[StockEntryId] [int] IDENTITY(1,1) NOT NULL,
	[SizeId] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UserId] [int] NULL,
	[Note] [nvarchar](500) NULL,
	[CreatedAt] [datetime] NOT NULL,
 CONSTRAINT [PK_StockEntries] PRIMARY KEY CLUSTERED 
(
	[StockEntryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SaleLines]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SaleLines](
	[SaleLineId] [int] IDENTITY(1,1) NOT NULL,
	[SaleId] [int] NOT NULL,
	[SizeId] [int] NOT NULL,
	[Product] [nvarchar](300) NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
	[ListPrice] [decimal](18, 2) NOT NULL,
	[LineTotal]  AS ([Quantity]*[UnitPrice]) PERSISTED,
	[OrjQty] [int] NULL,
 CONSTRAINT [PK_SaleLines] PRIMARY KEY CLUSTERED 
(
	[SaleLineId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_SizeStock]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[V_SizeStock]
AS
WITH InStock AS (
    SELECT SizeId, SUM(Quantity) AS Qty
    FROM dbo.StockEntries
    GROUP BY SizeId
),
OutStock AS (
    SELECT sl.SizeId, SUM(sl.Quantity) AS Qty
    FROM dbo.SaleLines sl
    GROUP BY sl.SizeId
)
SELECT
     SizeId = COALESCE(i.SizeId, o.SizeId) 
    ,InStock = i.qty
    ,OutStock = o.qty
    ,StockQty = ISNULL(i.Qty, 0) - ISNULL(o.Qty, 0)
    
FROM InStock i
FULL OUTER JOIN OutStock o ON o.SizeId = i.SizeId;
GO
/****** Object:  Table [dbo].[Currencies]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Currencies](
	[CurrencyId] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](10) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Currencies] PRIMARY KEY CLUSTERED 
(
	[CurrencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DeletedSize]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeletedSize](
	[DeletedSizeId] [int] IDENTITY(1,1) NOT NULL,
	[SizeId] [int] NOT NULL,
	[VariantId] [int] NULL,
	[Size] [varchar](50) NULL,
	[Barcode] [varchar](500) NULL,
	[SilinmeTarihi] [datetime] NOT NULL,
 CONSTRAINT [PK_DeletedSize] PRIMARY KEY CLUSTERED 
(
	[DeletedSizeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Grid]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Grid](
	[GridId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NULL,
 CONSTRAINT [PK_Grid] PRIMARY KEY CLUSTERED 
(
	[GridId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GridColumn]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GridColumn](
	[GridColumnId] [int] IDENTITY(1,1) NOT NULL,
	[GridId] [int] NULL,
	[ColumnName] [varchar](255) NULL,
	[Caption] [varchar](255) NULL,
	[Tooltip] [varchar](255) NULL,
	[Position] [int] NULL,
	[Visible] [bit] NULL,
	[Bold] [bit] NULL,
	[Centered] [bit] NULL,
	[Width] [int] NULL,
	[FormatAsNumber] [int] NULL,
	[Summary] [bit] NULL,
	[LookUpId] [int] NULL,
	[Expression] [varchar](max) NULL,
 CONSTRAINT [PK_GridColumn] PRIMARY KEY CLUSTERED 
(
	[GridColumnId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NameCategory]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NameCategory](
	[NameCategoryId] [int] IDENTITY(1,1) NOT NULL,
	[NameCategoryName] [nvarchar](200) NOT NULL,
	[NameCategoryDescription] [nvarchar](500) NULL,
 CONSTRAINT [PK_NameCategory] PRIMARY KEY CLUSTERED 
(
	[NameCategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OrderRequestLines]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderRequestLines](
	[OrderRequestLineId] [int] IDENTITY(1,1) NOT NULL,
	[OrderRequestId] [int] NOT NULL,
	[SizeId] [int] NOT NULL,
	[Product] [nvarchar](300) NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
	[ListPrice] [decimal](18, 2) NOT NULL,
	[LineTotal]  AS ([Quantity]*[UnitPrice]) PERSISTED,
 CONSTRAINT [PK_OrderRequestLines] PRIMARY KEY CLUSTERED 
(
	[OrderRequestLineId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OrderRequests]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderRequests](
	[OrderRequestId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[Customer] [nvarchar](200) NULL,
	[Note] [nvarchar](500) NULL,
	[Status] [nvarchar](20) NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
 CONSTRAINT [PK_OrderRequests] PRIMARY KEY CLUSTERED 
(
	[OrderRequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PaymentTypes]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentTypes](
	[PaymentTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_PaymentTypes] PRIMARY KEY CLUSTERED 
(
	[PaymentTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_PaymentTypes_Name] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PriceList]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PriceList](
	[PriceListId] [int] IDENTITY(1,1) NOT NULL,
	[Caption] [varchar](500) NULL,
	[InsertedOn] [datetime] NULL,
 CONSTRAINT [PK_PriceList] PRIMARY KEY CLUSTERED 
(
	[PriceListId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PriceListDetail]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PriceListDetail](
	[PriceListDetailId] [int] IDENTITY(1,1) NOT NULL,
	[PriceListId] [int] NULL,
	[StyleId] [int] NOT NULL,
	[PriceEUR] [decimal](18, 2) NULL,
	[PriceUSD] [decimal](18, 2) NULL,
	[PriceTL] [decimal](18, 2) NULL,
 CONSTRAINT [PK_PriceListDetail] PRIMARY KEY CLUSTERED 
(
	[PriceListDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RefreshTokens]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RefreshTokens](
	[RefreshTokenId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[Token] [nvarchar](512) NOT NULL,
	[ExpiresAt] [datetime] NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
 CONSTRAINT [PK_RefreshTokens] PRIMARY KEY CLUSTERED 
(
	[RefreshTokenId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_RefreshTokens_Token] UNIQUE NONCLUSTERED 
(
	[Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SaleLines_Old]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SaleLines_Old](
	[SaleLineId] [int] IDENTITY(1,1) NOT NULL,
	[SaleId] [int] NOT NULL,
	[SizeId] [int] NOT NULL,
	[Product] [nvarchar](300) NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NOT NULL,
	[ListPrice] [decimal](18, 2) NOT NULL,
	[LineTotal] [decimal](29, 2) NULL,
	[OrjQty] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Sales]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sales](
	[SaleId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[Customer] [nvarchar](200) NULL,
	[PaymentTypeId] [int] NULL,
	[Note] [nvarchar](500) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[OrderRequestId] [int] NULL,
	[DiscountPercent] [decimal](5, 2) NOT NULL,
	[DiscountFixedAmount] [decimal](18, 2) NOT NULL,
 CONSTRAINT [PK_Sales] PRIMARY KEY CLUSTERED 
(
	[SaleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockEntries_old]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockEntries_old](
	[StockEntryId] [int] IDENTITY(1,1) NOT NULL,
	[SizeId] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UserId] [int] NULL,
	[Note] [nvarchar](500) NULL,
	[CreatedAt] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockWebhookInbound]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockWebhookInbound](
	[EventId] [uniqueidentifier] NOT NULL,
	[SkuCode] [nvarchar](200) NOT NULL,
	[Quantity] [int] NOT NULL,
	[ResultCode] [int] NOT NULL,
	[Adjusted] [bit] NOT NULL,
	[ErrorMessage] [nvarchar](200) NULL,
	[ReceivedAt] [datetime2](7) NOT NULL,
	[EventType] [nvarchar](40) NOT NULL,
	[OnHand] [int] NULL,
	[InboundId] [bigint] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_StockWebhookInbound] PRIMARY KEY CLUSTERED 
(
	[InboundId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_StockWebhookInbound_EventId] UNIQUE NONCLUSTERED 
(
	[EventId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StockWebhookOutbound]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockWebhookOutbound](
	[OutboundId] [bigint] IDENTITY(1,1) NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[EventType] [nvarchar](40) NOT NULL,
	[SizeId] [int] NOT NULL,
	[SkuCode] [nvarchar](200) NOT NULL,
	[Quantity] [int] NOT NULL,
	[OnHand] [int] NOT NULL,
	[CreatedAt] [datetimeoffset](7) NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[Attempts] [int] NOT NULL,
	[LastError] [nvarchar](4000) NULL,
	[SentAt] [datetimeoffset](7) NULL,
 CONSTRAINT [PK_StockWebhookOutbound] PRIMARY KEY CLUSTERED 
(
	[OutboundId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_StockWebhookOutbound_EventId] UNIQUE NONCLUSTERED 
(
	[EventId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](256) NULL,
	[PasswordHash] [varbinary](64) NOT NULL,
	[Status] [nvarchar](20) NOT NULL,
	[Role] [nvarchar](20) NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
	[UpdatedAt] [datetime] NULL,
	[Username] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WebSizeType]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebSizeType](
	[WebSizeTypeId] [int] IDENTITY(1,1) NOT NULL,
	[WebSizeTypeName] [nvarchar](150) NOT NULL,
	[WebSizeTypeCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_SizeType] PRIMARY KEY CLUSTERED 
(
	[WebSizeTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_SizeType_Code] UNIQUE NONCLUSTERED 
(
	[WebSizeTypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Year]    Script Date: 30.08.2026 06:43:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Year](
	[YearId] [int] IDENTITY(1,1) NOT NULL,
	[YearCode] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_Year] PRIMARY KEY CLUSTERED 
(
	[YearId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Year_YearCode] UNIQUE NONCLUSTERED 
(
	[YearCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OrderRequests] ADD  CONSTRAINT [DF_OrderRequests_Status]  DEFAULT (N'Pending') FOR [Status]
GO
ALTER TABLE [dbo].[OrderRequests] ADD  CONSTRAINT [DF_OrderRequests_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[RefreshTokens] ADD  CONSTRAINT [DF_RefreshTokens_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Sales] ADD  CONSTRAINT [DF_Sales_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Sales] ADD  CONSTRAINT [DF_Sales_DiscountPercent]  DEFAULT ((0)) FOR [DiscountPercent]
GO
ALTER TABLE [dbo].[Sales] ADD  CONSTRAINT [DF_Sales_DiscountFixedAmount]  DEFAULT ((0)) FOR [DiscountFixedAmount]
GO
ALTER TABLE [dbo].[StockEntries] ADD  CONSTRAINT [DF_StockEntries_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[StockWebhookInbound] ADD  CONSTRAINT [DF_StockWebhookInbound_Adjusted]  DEFAULT ((0)) FOR [Adjusted]
GO
ALTER TABLE [dbo].[StockWebhookInbound] ADD  CONSTRAINT [DF_StockWebhookInbound_ReceivedAt]  DEFAULT (sysutcdatetime()) FOR [ReceivedAt]
GO
ALTER TABLE [dbo].[StockWebhookInbound] ADD  CONSTRAINT [DF_StockWebhookInbound_EventType]  DEFAULT (N'') FOR [EventType]
GO
ALTER TABLE [dbo].[StockWebhookOutbound] ADD  CONSTRAINT [DF_StockWebhookOutbound_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[StockWebhookOutbound] ADD  CONSTRAINT [DF_StockWebhookOutbound_Status]  DEFAULT (N'Pending') FOR [Status]
GO
ALTER TABLE [dbo].[StockWebhookOutbound] ADD  CONSTRAINT [DF_StockWebhookOutbound_Attempts]  DEFAULT ((0)) FOR [Attempts]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_Status]  DEFAULT (N'Pending') FOR [Status]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_Role]  DEFAULT (N'Member') FOR [Role]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_CreatedAt]  DEFAULT (getdate()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[OrderRequestLines]  WITH CHECK ADD  CONSTRAINT [FK_OrderRequestLines_OrderRequests] FOREIGN KEY([OrderRequestId])
REFERENCES [dbo].[OrderRequests] ([OrderRequestId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OrderRequestLines] CHECK CONSTRAINT [FK_OrderRequestLines_OrderRequests]
GO
ALTER TABLE [dbo].[OrderRequests]  WITH CHECK ADD  CONSTRAINT [FK_OrderRequests_Currencies] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([CurrencyId])
GO
ALTER TABLE [dbo].[OrderRequests] CHECK CONSTRAINT [FK_OrderRequests_Currencies]
GO
ALTER TABLE [dbo].[SaleLines]  WITH CHECK ADD  CONSTRAINT [FK_SaleLines_Sales] FOREIGN KEY([SaleId])
REFERENCES [dbo].[Sales] ([SaleId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SaleLines] CHECK CONSTRAINT [FK_SaleLines_Sales]
GO
ALTER TABLE [dbo].[Sales]  WITH CHECK ADD  CONSTRAINT [FK_Sales_Currencies] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([CurrencyId])
GO
ALTER TABLE [dbo].[Sales] CHECK CONSTRAINT [FK_Sales_Currencies]
GO
ALTER TABLE [dbo].[Sales]  WITH CHECK ADD  CONSTRAINT [FK_Sales_OrderRequests] FOREIGN KEY([OrderRequestId])
REFERENCES [dbo].[OrderRequests] ([OrderRequestId])
GO
ALTER TABLE [dbo].[Sales] CHECK CONSTRAINT [FK_Sales_OrderRequests]
GO
ALTER TABLE [dbo].[Sales]  WITH CHECK ADD  CONSTRAINT [FK_Sales_PaymentTypes] FOREIGN KEY([PaymentTypeId])
REFERENCES [dbo].[PaymentTypes] ([PaymentTypeId])
GO
ALTER TABLE [dbo].[Sales] CHECK CONSTRAINT [FK_Sales_PaymentTypes]
GO
ALTER TABLE [dbo].[OrderRequestLines]  WITH CHECK ADD  CONSTRAINT [CK_OrderRequestLines_Quantity] CHECK  (([Quantity]>(0)))
GO
ALTER TABLE [dbo].[OrderRequestLines] CHECK CONSTRAINT [CK_OrderRequestLines_Quantity]
GO
ALTER TABLE [dbo].[OrderRequests]  WITH CHECK ADD  CONSTRAINT [CK_OrderRequests_Status] CHECK  (([Status]=N'Converted' OR [Status]=N'Rejected' OR [Status]=N'Accepted' OR [Status]=N'Pending'))
GO
ALTER TABLE [dbo].[OrderRequests] CHECK CONSTRAINT [CK_OrderRequests_Status]
GO
ALTER TABLE [dbo].[SaleLines]  WITH CHECK ADD  CONSTRAINT [CK_SaleLines_ListPrice] CHECK  (([ListPrice]>=(0)))
GO
ALTER TABLE [dbo].[SaleLines] CHECK CONSTRAINT [CK_SaleLines_ListPrice]
GO
ALTER TABLE [dbo].[SaleLines]  WITH CHECK ADD  CONSTRAINT [CK_SaleLines_UnitPrice] CHECK  (([UnitPrice]>=(0)))
GO
ALTER TABLE [dbo].[SaleLines] CHECK CONSTRAINT [CK_SaleLines_UnitPrice]
GO
ALTER TABLE [dbo].[StockEntries]  WITH CHECK ADD  CONSTRAINT [CK_StockEntries_Quantity] CHECK  (([Quantity]>(0)))
GO
ALTER TABLE [dbo].[StockEntries] CHECK CONSTRAINT [CK_StockEntries_Quantity]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [CK_Users_Role] CHECK  (([Role]=N'Staff' OR [Role]=N'Member'))
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [CK_Users_Role]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [CK_Users_Status] CHECK  (([Status]=N'Deleted' OR [Status]=N'Rejected' OR [Status]=N'Approved' OR [Status]=N'Pending'))
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [CK_Users_Status]
GO
/****** Object:  StoredProcedure [dbo].[API_Auth_ChangePassword]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Auth_ChangePassword]
    @UserId INT,
    @CurrentPassword NVARCHAR(256),
    @NewPassword NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF LEN(@NewPassword) < 2
    BEGIN
        RAISERROR(N'Yeni şifre en az 2 karakter olmalıdır.', 16, 1);
        RETURN;
    END

    IF @CurrentPassword = @NewPassword
    BEGIN
        RAISERROR(N'Yeni şifre mevcut şifreden farklı olmalıdır.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Users u
        WHERE u.UserId = @UserId
          AND u.PasswordHash = HASHBYTES('SHA2_256', @CurrentPassword)
          AND u.Status <> N'Rejected'
          AND u.Status <> N'Deleted'
    )
    BEGIN
        RAISERROR(N'Mevcut şifre hatalı.', 16, 1);
        RETURN;
    END

    UPDATE dbo.Users
    SET PasswordHash = HASHBYTES('SHA2_256', @NewPassword)
    WHERE UserId = @UserId;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Auth_DeleteAccount]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Auth_DeleteAccount]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: soft-delete vs hard-delete per existing schema
    UPDATE dbo.Users
    SET
        Status = N'Deleted',
        Username = CONCAT(N'deleted_', @UserId, N'_', Username),
        Email = CASE
            WHEN Email IS NOT NULL THEN CONCAT(N'deleted_', @UserId, N'_', Email)
            ELSE NULL
        END
    WHERE UserId = @UserId AND Status <> N'Deleted';

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Auth_GetProfile]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Auth_GetProfile]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.Status, u.Role, u.CreatedAt
    FROM dbo.Users u
    WHERE u.UserId = @UserId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Auth_Login]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Auth_Login]
    @Username NVARCHAR(50),
    @Password NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Username = LTRIM(RTRIM(@Username));

    SELECT u.UserId, u.Username, u.Status, u.Role
    FROM dbo.Users u
    WHERE u.Username COLLATE SQL_Latin1_General_CP1_CI_AS = @Username COLLATE SQL_Latin1_General_CP1_CI_AS
      AND u.PasswordHash = HASHBYTES('SHA2_256', @Password)
      AND u.Status <> N'Rejected';
END
GO
/****** Object:  StoredProcedure [dbo].[API_Auth_RefreshToken]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Auth_RefreshToken]
    @RefreshToken NVARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.UserId, u.Username, u.Status
    FROM dbo.RefreshTokens rt
    INNER JOIN dbo.Users u ON u.UserId = rt.UserId
    WHERE rt.Token = @RefreshToken
      AND rt.ExpiresAt > GETDATE()
      AND u.Status <> N'Rejected';
END
GO
/****** Object:  StoredProcedure [dbo].[API_Auth_Register]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Auth_Register]
    @Username NVARCHAR(50),
    @Password NVARCHAR(256),
    @AcceptedTerms BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Username = LTRIM(RTRIM(@Username));

    IF @AcceptedTerms <> 1
    BEGIN
        RAISERROR(N'Kullanım şartları kabul edilmelidir.', 16, 1);
        RETURN;
    END

    IF LEN(@Username) < 2
    BEGIN
        RAISERROR(N'Kullanıcı adı en az 2 karakter olmalıdır.', 16, 1);
        RETURN;
    END

    IF LEN(@Password) < 2
    BEGIN
        RAISERROR(N'Şifre en az 2 karakter olmalıdır.', 16, 1);
        RETURN;
    END

    IF @Username LIKE N'%[^a-zA-Z0-9_]%'
    BEGIN
        RAISERROR(N'Geçersiz kullanıcı adı formatı.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM dbo.Users
        WHERE Username COLLATE SQL_Latin1_General_CP1_CI_AS = @Username COLLATE SQL_Latin1_General_CP1_CI_AS
    )
    BEGIN
        RAISERROR(N'Bu kullanıcı adı zaten kayıtlı.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.Users (Username, PasswordHash, Status, Role, CreatedAt)
    VALUES (@Username, HASHBYTES('SHA2_256', @Password), N'Pending', N'Member', GETDATE());

    SELECT
        CAST(SCOPE_IDENTITY() AS INT) AS UserId,
        @Username AS Username,
        N'Pending' AS Status,
        N'Member' AS Role;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Get_Currency]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Get_Currency]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.CurrencyId, c.Code, c.Name
    FROM dbo.Currencies c
    ORDER BY c.CurrencyId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Lookup_Customers]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Lookup_Customers]
    @Search NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Customers table
    SELECT c.CustomerId, c.Name
    FROM dbo.Customers c
    WHERE @Search IS NULL OR c.Name LIKE N'%' + @Search + N'%'
    ORDER BY c.Name;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Lookup_PaymentTypes]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Lookup_PaymentTypes]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT pt.PaymentTypeId, pt.Name
    FROM dbo.PaymentTypes pt
    ORDER BY pt.Name;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Membership_Approve]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Membership_Approve]
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
/****** Object:  StoredProcedure [dbo].[API_Membership_ListPending]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Membership_ListPending]
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO-ADAPT: Users table
    SELECT u.UserId, u.Username, u.Status, u.CreatedAt
    FROM dbo.Users u
    WHERE u.Status = 'Pending'
    ORDER BY u.CreatedAt;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Membership_Reject]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Membership_Reject]
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
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_Convert]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_Convert]
    @UserId INT,
    @OrderRequestId INT,
    @PaymentTypeId INT = NULL,
    @Note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(20);
    DECLARE @CurrencyId INT;
    DECLARE @Customer NVARCHAR(200);
    DECLARE @OrderNote NVARCHAR(500);
    DECLARE @SaleId INT;

    SELECT
        @Status = Status,
        @CurrencyId = CurrencyId,
        @Customer = Customer,
        @OrderNote = Note
    FROM dbo.OrderRequests
    WHERE OrderRequestId = @OrderRequestId;

    IF @Status IS NULL
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    IF @Status = N'Converted'
    BEGIN
        RAISERROR(N'Sipariş talebi zaten satışa dönüştürülmüş.', 16, 1);
        RETURN;
    END

    IF @Status = N'Rejected'
    BEGIN
        RAISERROR(N'Reddedilmiş sipariş talebi satışa dönüştürülemez.', 16, 1);
        RETURN;
    END

    IF @Status NOT IN (N'Pending', N'Accepted')
    BEGIN
        RAISERROR(N'Bu talep satışa dönüştürülemez.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.OrderRequestLines
        WHERE OrderRequestId = @OrderRequestId
    )
    BEGIN
        RAISERROR(N'Sipariş talebi en az bir kalem içermelidir.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    INSERT INTO dbo.Sales (UserId, CurrencyId, Customer, PaymentTypeId, Note, OrderRequestId, CreatedAt)
    VALUES (
        @UserId,
        @CurrencyId,
        @Customer,
        @PaymentTypeId,
        COALESCE(@Note, @OrderNote),
        @OrderRequestId,
        GETDATE()
    );

    SET @SaleId = SCOPE_IDENTITY();

    INSERT INTO dbo.SaleLines (SaleId, SizeId, Product, Quantity, UnitPrice, ListPrice)
    SELECT
        @SaleId,
        ol.SizeId,
        ol.Product,
        ol.Quantity,
        ol.UnitPrice,
        ol.ListPrice
    FROM dbo.OrderRequestLines ol
    WHERE ol.OrderRequestId = @OrderRequestId;

    UPDATE dbo.OrderRequests
    SET Status = N'Converted'
    WHERE OrderRequestId = @OrderRequestId;

    COMMIT TRANSACTION;

    SELECT
        @SaleId AS SaleId,
        @OrderRequestId AS OrderRequestId,
        (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId) AS TotalAmount;
END
GO
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_Create]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_Create]
    @UserId INT,
    @CurrencyId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @Lines NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.Users
        WHERE UserId = @UserId AND Role = N'Staff'
    )
    BEGIN
        RAISERROR(N'Personel hesapları sipariş talebi oluşturamaz.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    DECLARE @OrderRequestId INT;

    INSERT INTO dbo.OrderRequests (UserId, CurrencyId, Customer, Note, Status, CreatedAt)
    VALUES (@UserId, @CurrencyId, @Customer, @Note, N'Pending', GETDATE());

    SET @OrderRequestId = SCOPE_IDENTITY();

    INSERT INTO dbo.OrderRequestLines (OrderRequestId, SizeId, Product, Quantity, UnitPrice, ListPrice)
    SELECT
        @OrderRequestId,
        j.SizeId,
        j.Product,
        j.Quantity,
        j.UnitPrice,
        j.ListPrice
    FROM OPENJSON(@Lines)
    WITH (
        SizeId INT '$.SizeId',
        Product NVARCHAR(300) '$.Product',
        Quantity INT '$.Quantity',
        UnitPrice DECIMAL(18, 2) '$.UnitPrice',
        ListPrice DECIMAL(18, 2) '$.ListPrice'
    ) AS j;

    COMMIT TRANSACTION;

    SELECT
        @OrderRequestId AS OrderRequestId,
        (SELECT SUM(ol.LineTotal) FROM dbo.OrderRequestLines ol WHERE ol.OrderRequestId = @OrderRequestId) AS TotalAmount;
END
GO
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_Get]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_Get]
    @OrderRequestId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.OrderRequests WHERE OrderRequestId = @OrderRequestId)
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT
        o.OrderRequestId,
        o.UserId,
        u.Username AS MemberEmail,
        o.CurrencyId,
        o.Customer,
        o.Note,
        o.Status,
        o.CreatedAt,
        ConvertedSaleId = (
            SELECT TOP 1 s.SaleId
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        ConvertedSaleDiscountPercent = (
            SELECT TOP 1 s.DiscountPercent
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        ConvertedSaleDiscountFixedAmount = (
            SELECT TOP 1 s.DiscountFixedAmount
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        ConvertedSaleSubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.Sales s
            INNER JOIN dbo.SaleLines sl ON sl.SaleId = s.SaleId
            WHERE s.OrderRequestId = o.OrderRequestId
        ),
        ConvertedSaleNetTotal = (
            SELECT TOP 1 dbo.fn_Sale_NetTotal(
                (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = s.SaleId),
                s.DiscountPercent,
                s.DiscountFixedAmount
            )
            FROM dbo.Sales s
            WHERE s.OrderRequestId = o.OrderRequestId
            ORDER BY s.SaleId DESC
        ),
        TotalAmount = (
            SELECT SUM(ol.LineTotal)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        ),
        Lines = (
            SELECT
                ol.OrderRequestLineId,
                ol.SizeId,
                ol.Product,
                ol.Quantity,
                ol.UnitPrice,
                ol.ListPrice,
                ol.LineTotal,
                StockQty = ISNULL(st.StockQty, 0),
                ps.ProductCode,
                ps.StyleName,
                ps.Color,
                ps.Size
            FROM dbo.OrderRequestLines ol
            LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ol.SizeId
            LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = ol.SizeId
            WHERE ol.OrderRequestId = o.OrderRequestId
            FOR JSON PATH
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE o.OrderRequestId = @OrderRequestId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_GetMine]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_GetMine]
    @UserId INT,
    @OrderRequestId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.OrderRequests
        WHERE OrderRequestId = @OrderRequestId AND UserId = @UserId
    )
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT
        o.OrderRequestId,
        o.UserId,
        u.Username AS MemberEmail,
        o.CurrencyId,
        o.Customer,
        o.Note,
        o.Status,
        o.CreatedAt,
        TotalAmount = (
            SELECT SUM(ol.LineTotal)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        ),
        Lines = (
            SELECT
                ol.OrderRequestLineId,
                ol.SizeId,
                ol.Product,
                ol.Quantity,
                ol.UnitPrice,
                ol.ListPrice,
                ol.LineTotal,
                ps.ProductCode,
                ps.StyleName,
                ps.Color,
                ps.Size
            FROM dbo.OrderRequestLines ol
            LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = ol.SizeId
            WHERE ol.OrderRequestId = o.OrderRequestId
            FOR JSON PATH
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE o.OrderRequestId = @OrderRequestId
      AND o.UserId = @UserId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_List]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_List]
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL,
    @Status NVARCHAR(20) = NULL,
    @Page INT = 1,
    @PageSize INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 30;

    SELECT
        o.OrderRequestId,
        o.UserId,
        u.Username AS MemberEmail,
        o.CurrencyId,
        o.Customer,
        o.Note,
        o.Status,
        o.CreatedAt,
        TotalAmount = (
            SELECT SUM(ol.LineTotal)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        ),
        LineCount = (
            SELECT COUNT(*)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE (@DateFrom IS NULL OR CAST(o.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(o.CreatedAt AS DATE) <= @DateTo)
      AND (@Status IS NULL OR @Status = N'' OR o.Status = @Status)
    ORDER BY o.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_ListMine]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_ListMine]
    @UserId INT,
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL,
    @Status NVARCHAR(20) = NULL,
    @Page INT = 1,
    @PageSize INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 30;

    SELECT
        o.OrderRequestId,
        o.UserId,
        u.Username AS MemberEmail,
        o.CurrencyId,
        o.Customer,
        o.Note,
        o.Status,
        o.CreatedAt,
        TotalAmount = (
            SELECT SUM(ol.LineTotal)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        ),
        LineCount = (
            SELECT COUNT(*)
            FROM dbo.OrderRequestLines ol
            WHERE ol.OrderRequestId = o.OrderRequestId
        )
    FROM dbo.OrderRequests o
    INNER JOIN dbo.Users u ON u.UserId = o.UserId
    WHERE o.UserId = @UserId
      AND (@DateFrom IS NULL OR CAST(o.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(o.CreatedAt AS DATE) <= @DateTo)
      AND (@Status IS NULL OR @Status = N'' OR o.Status = @Status)
    ORDER BY o.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[API_OrderRequest_Update]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_OrderRequest_Update]
    @OrderRequestId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @Status NVARCHAR(20) = NULL,
    @Lines NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(20);

    SELECT @CurrentStatus = Status
    FROM dbo.OrderRequests
    WHERE OrderRequestId = @OrderRequestId;

    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
        RETURN;
    END

    IF @CurrentStatus IN (N'Converted', N'Rejected')
    BEGIN
        RAISERROR(N'Tamamlanmış veya reddedilmiş talepler düzenlenemez.', 16, 1);
        RETURN;
    END

    IF @Status IS NOT NULL AND @Status <> N'Rejected'
    BEGIN
        RAISERROR(N'Yalnızca reddetme işlemi desteklenir.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.OrderRequests
    SET
        Customer = COALESCE(@Customer, Customer),
        Note = COALESCE(@Note, Note),
        Status = COALESCE(@Status, Status)
    WHERE OrderRequestId = @OrderRequestId;

    IF @Lines IS NOT NULL AND (@Status IS NULL OR @Status <> N'Rejected')
    BEGIN
        DELETE FROM dbo.OrderRequestLines
        WHERE OrderRequestId = @OrderRequestId;

        INSERT INTO dbo.OrderRequestLines (OrderRequestId, SizeId, Product, Quantity, UnitPrice, ListPrice)
        SELECT
            @OrderRequestId,
            j.SizeId,
            j.Product,
            j.Quantity,
            j.UnitPrice,
            j.ListPrice
        FROM OPENJSON(@Lines)
        WITH (
            SizeId INT '$.SizeId',
            Product NVARCHAR(300) '$.Product',
            Quantity INT '$.Quantity',
            UnitPrice DECIMAL(18, 2) '$.UnitPrice',
            ListPrice DECIMAL(18, 2) '$.ListPrice'
        ) AS j
        WHERE j.Quantity > 0;

        IF NOT EXISTS (SELECT 1 FROM dbo.OrderRequestLines WHERE OrderRequestId = @OrderRequestId)
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'Sipariş en az bir kalem içermelidir.', 16, 1);
            RETURN;
        END
    END

    COMMIT TRANSACTION;

    SELECT
        @OrderRequestId AS OrderRequestId,
        (SELECT SUM(ol.LineTotal) FROM dbo.OrderRequestLines ol WHERE ol.OrderRequestId = @OrderRequestId) AS TotalAmount;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Product_GetByBarcode]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Product_GetByBarcode]
    @Barcode NVARCHAR(50),
    @CurrencyId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        ss.SizeId,
        ss.Barcode,
        ss.StyleName,
        ss.ProductName,
        ss.Color,
        ss.Size,
        ss.ProductCode,
        s.PriceTL,
        s.PriceEUR,
        s.PriceUSD,
        StockQty = ISNULL(st.StockQty, 0)
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.Barcode = @Barcode;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Product_List]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Product_List]
    @Search NVARCHAR(100) = NULL,
    @CurrencyId INT = NULL,
    @Page INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 20;

    SELECT
        ss.SizeId,
        ss.Barcode,
        ss.StyleName,
        ss.ProductName,
        ss.Color,
        ss.Size,
        ss.ProductCode,
        s.PriceTL,
        s.PriceEUR,
        s.PriceUSD,
        StockQty = ISNULL(st.StockQty, 0)
    FROM dbo.V_ProductSize ss
    INNER JOIN dbo.Style s ON s.StyleId = ss.StyleId
    LEFT JOIN dbo.V_SizeStock st ON st.SizeId = ss.SizeId
    WHERE ss.SizeId IS NOT NULL
      AND (
          @Search IS NULL
       OR @Search = N''
       OR ss.ProductName LIKE N'%' + @Search + N'%'
       OR ss.StyleName LIKE N'%' + @Search + N'%'
       OR ss.Barcode LIKE N'%' + @Search + N'%')
    ORDER BY ss.StyleName, ss.ProductName, ss.SizeId
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Report_SalesByProduct]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Report_SalesByProduct]
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sl.Product,
        ps.StyleName,
        ps.ProductCode,
        ps.Color,
        sl.SizeId,
        ps.Size AS SizeLabel,
        SUM(sl.Quantity) AS Quantity,
        SUM(sl.LineTotal) AS Amount
    FROM dbo.SaleLines sl
    INNER JOIN dbo.Sales s ON s.SaleId = sl.SaleId
    LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = sl.SizeId
    WHERE (@DateFrom IS NULL OR CAST(s.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(s.CreatedAt AS DATE) <= @DateTo)
    GROUP BY
        sl.Product,
        ps.StyleName,
        ps.ProductCode,
        ps.Color,
        sl.SizeId,
        ps.Size
    ORDER BY
        ps.StyleName,
        sl.Product,
        ps.Size;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Sale_Create]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Sale_Create]
    @UserId INT,
    @CurrencyId INT,
    @Customer NVARCHAR(200) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX),
    @Note NVARCHAR(500) = NULL,
    @OrderRequestId INT = NULL,
    @DiscountPercent DECIMAL(5, 2) = 0,
    @DiscountFixedAmount DECIMAL(18, 2) = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @DiscountPercent < 0 SET @DiscountPercent = 0;
    IF @DiscountPercent > 100 SET @DiscountPercent = 100;
    IF @DiscountFixedAmount < 0 SET @DiscountFixedAmount = 0;

    IF @OrderRequestId IS NOT NULL
    BEGIN
        DECLARE @OrderStatus NVARCHAR(20);

        SELECT @OrderStatus = Status
        FROM dbo.OrderRequests
        WHERE OrderRequestId = @OrderRequestId;

        IF @OrderStatus IS NULL
        BEGIN
            RAISERROR(N'Sipariş talebi bulunamadı.', 16, 1);
            RETURN;
        END

        IF @OrderStatus IN (N'Converted', N'Rejected')
        BEGIN
            RAISERROR(N'Bu talep satışa dönüştürülemez.', 16, 1);
            RETURN;
        END
    END

    BEGIN TRANSACTION;

    DECLARE @SaleId INT;

    INSERT INTO dbo.Sales (
        UserId, CurrencyId, Customer, PaymentTypeId, Note, OrderRequestId,
        DiscountPercent, DiscountFixedAmount, CreatedAt
    )
    VALUES (
        @UserId, @CurrencyId, @Customer, @PaymentTypeId, @Note, @OrderRequestId,
        @DiscountPercent, @DiscountFixedAmount, GETDATE()
    );

    SET @SaleId = SCOPE_IDENTITY();

    INSERT INTO dbo.SaleLines (SaleId, SizeId, Product, Quantity, UnitPrice, ListPrice)
    SELECT
        @SaleId,
        j.SizeId,
        j.Product,
        j.Quantity,
        j.UnitPrice,
        j.ListPrice
    FROM OPENJSON(@Lines)
    WITH (
        SizeId INT '$.SizeId',
        Product NVARCHAR(300) '$.Product',
        Quantity INT '$.Quantity',
        UnitPrice DECIMAL(18, 2) '$.UnitPrice',
        ListPrice DECIMAL(18, 2) '$.ListPrice'
    ) AS j;

    IF @OrderRequestId IS NOT NULL
    BEGIN
        UPDATE dbo.OrderRequests
        SET Status = N'Converted'
        WHERE OrderRequestId = @OrderRequestId;
    END

    COMMIT TRANSACTION;

    SELECT
        @SaleId AS SaleId,
        @OrderRequestId AS OrderRequestId,
        SubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = @SaleId
        ),
        DiscountPercent = @DiscountPercent,
        DiscountFixedAmount = @DiscountFixedAmount,
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = @SaleId),
            @DiscountPercent,
            @DiscountFixedAmount
        );
END
GO
/****** Object:  StoredProcedure [dbo].[API_Sale_Delete]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Sale_Delete]
    @SaleId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrderRequestId INT;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT @OrderRequestId = OrderRequestId
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    BEGIN TRANSACTION;

    DELETE FROM dbo.SaleLines
    WHERE SaleId = @SaleId;

    DELETE FROM dbo.Sales
    WHERE SaleId = @SaleId;

    IF @OrderRequestId IS NOT NULL
    BEGIN
        UPDATE dbo.OrderRequests
        SET Status = N'Pending'
        WHERE OrderRequestId = @OrderRequestId
          AND Status = N'Converted';
    END

    COMMIT TRANSACTION;

    SELECT @SaleId AS SaleId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Sale_Get]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Sale_Get]
    @SaleId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

    SELECT
        s.SaleId,
        s.UserId,
        u.Username AS StaffEmail,
        s.CurrencyId,
        s.Customer,
        s.Note,
        s.PaymentTypeId,
        s.OrderRequestId,
        s.CreatedAt,
        s.DiscountPercent,
        s.DiscountFixedAmount,
        SubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = s.SaleId
        ),
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = s.SaleId),
            s.DiscountPercent,
            s.DiscountFixedAmount
        ),
        Lines = (
            SELECT
                sl.SaleLineId,
                sl.SizeId,
                sl.Product,
                sl.Quantity,
                sl.UnitPrice,
                sl.ListPrice,
                sl.LineTotal,
                StockQty = ISNULL(st.StockQty, 0)
            FROM dbo.SaleLines sl
            LEFT JOIN dbo.V_SizeStock st ON st.SizeId = sl.SizeId
            WHERE sl.SaleId = s.SaleId
            FOR JSON PATH
        )
    FROM dbo.Sales s
    INNER JOIN dbo.Users u ON u.UserId = s.UserId
    WHERE s.SaleId = @SaleId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Sale_List]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Sale_List]
    @DateFrom DATE = NULL,
    @DateTo DATE = NULL,
    @Page INT = 1,
    @PageSize INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    IF @Page < 1 SET @Page = 1;
    IF @PageSize < 1 OR @PageSize > 100 SET @PageSize = 30;

    SELECT
        s.SaleId,
        s.UserId,
        u.Username AS StaffEmail,
        s.CurrencyId,
        s.Customer,
        s.Note,
        s.PaymentTypeId,
        s.OrderRequestId,
        s.CreatedAt,
        s.DiscountPercent,
        s.DiscountFixedAmount,
        SubtotalAmount = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = s.SaleId
        ),
        TotalAmount = dbo.fn_Sale_NetTotal(
            (SELECT SUM(sl.LineTotal) FROM dbo.SaleLines sl WHERE sl.SaleId = s.SaleId),
            s.DiscountPercent,
            s.DiscountFixedAmount
        ),
        LineCount = (
            SELECT COUNT(*)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = s.SaleId
        )
    FROM dbo.Sales s
    INNER JOIN dbo.Users u ON u.UserId = s.UserId
    WHERE (@DateFrom IS NULL OR CAST(s.CreatedAt AS DATE) >= @DateFrom)
      AND (@DateTo IS NULL OR CAST(s.CreatedAt AS DATE) <= @DateTo)
    ORDER BY s.CreatedAt DESC
    OFFSET (@Page - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
/****** Object:  StoredProcedure [dbo].[API_Sale_Update]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Sale_Update]
    @SaleId INT,
    @Customer NVARCHAR(200) = NULL,
    @Note NVARCHAR(500) = NULL,
    @PaymentTypeId INT = NULL,
    @Lines NVARCHAR(MAX) = NULL,
    @DiscountPercent DECIMAL(5, 2) = NULL,
    @DiscountFixedAmount DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Sales WHERE SaleId = @SaleId)
    BEGIN
        RAISERROR(N'Satış bulunamadı.', 16, 1);
        RETURN;
    END

    IF @DiscountPercent IS NOT NULL AND @DiscountPercent < 0 SET @DiscountPercent = 0;
    IF @DiscountPercent IS NOT NULL AND @DiscountPercent > 100 SET @DiscountPercent = 100;
    IF @DiscountFixedAmount IS NOT NULL AND @DiscountFixedAmount < 0 SET @DiscountFixedAmount = 0;

    BEGIN TRANSACTION;

    UPDATE dbo.Sales
    SET
        Customer = COALESCE(@Customer, Customer),
        Note = COALESCE(@Note, Note),
        PaymentTypeId = COALESCE(@PaymentTypeId, PaymentTypeId),
        DiscountPercent = COALESCE(@DiscountPercent, DiscountPercent),
        DiscountFixedAmount = COALESCE(@DiscountFixedAmount, DiscountFixedAmount)
    WHERE SaleId = @SaleId;

    IF @Lines IS NOT NULL
    BEGIN
        DELETE FROM dbo.SaleLines
        WHERE SaleId = @SaleId;

        INSERT INTO dbo.SaleLines (SaleId, SizeId, Product, Quantity, UnitPrice, ListPrice)
        SELECT
            @SaleId,
            j.SizeId,
            j.Product,
            j.Quantity,
            j.UnitPrice,
            j.ListPrice
        FROM OPENJSON(@Lines)
        WITH (
            SizeId INT '$.SizeId',
            Product NVARCHAR(300) '$.Product',
            Quantity INT '$.Quantity',
            UnitPrice DECIMAL(18, 2) '$.UnitPrice',
            ListPrice DECIMAL(18, 2) '$.ListPrice'
        ) AS j
        WHERE j.Quantity > 0;

        IF NOT EXISTS (SELECT 1 FROM dbo.SaleLines WHERE SaleId = @SaleId)
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR(N'Satış en az bir kalem içermelidir.', 16, 1);
            RETURN;
        END
    END

    COMMIT TRANSACTION;

    DECLARE @Subtotal DECIMAL(18, 2);
    DECLARE @Percent DECIMAL(5, 2);
    DECLARE @Fixed DECIMAL(18, 2);

    SELECT
        @Subtotal = (
            SELECT SUM(sl.LineTotal)
            FROM dbo.SaleLines sl
            WHERE sl.SaleId = @SaleId
        ),
        @Percent = DiscountPercent,
        @Fixed = DiscountFixedAmount
    FROM dbo.Sales
    WHERE SaleId = @SaleId;

    SELECT
        @SaleId AS SaleId,
        SubtotalAmount = @Subtotal,
        DiscountPercent = @Percent,
        DiscountFixedAmount = @Fixed,
        TotalAmount = dbo.fn_Sale_NetTotal(@Subtotal, @Percent, @Fixed);
END
GO
/****** Object:  StoredProcedure [dbo].[API_Stock_Entry]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_Stock_Entry]
    @UserId INT,
    @SizeId INT,
    @Quantity INT,
    @Note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Quantity <= 0
    BEGIN
        RAISERROR(N'Miktar 0''dan büyük olmalıdır.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.V_ProductSize WHERE SizeId = @SizeId)
    BEGIN
        RAISERROR(N'Ürün bulunamadı.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.StockEntries (SizeId, Quantity, UserId, Note)
    VALUES (@SizeId, @Quantity, @UserId, @Note);

    SELECT
        SCOPE_IDENTITY() AS StockEntryId,
        @SizeId AS SizeId,
        ISNULL((SELECT StockQty FROM dbo.V_SizeStock WHERE SizeId = @SizeId), 0) AS StockQty;
END
GO
/****** Object:  StoredProcedure [dbo].[API_WebHook_ApplyStock]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_WebHook_ApplyStock]
    @EventId UNIQUEIDENTIFIER,
    @EventType NVARCHAR(40),
    @SkuCode NVARCHAR(200),
    @Quantity INT,
    @UserId INT = 7
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @UserId = ISNULL(@UserId, 7);

    DECLARE @ResultCode INT;
    DECLARE @ErrorMessage NVARCHAR(400);
    DECLARE @OnHand INT;
    DECLARE @SizeId INT;
    DECLARE @MatchCount INT;
    DECLARE @CurrencyId INT;
    DECLARE @PaymentTypeId INT;
    DECLARE @SaleId INT;
    DECLARE @NormalizedType NVARCHAR(40) = LOWER(LTRIM(RTRIM(@EventType)));
    DECLARE @NormalizedSku NVARCHAR(200) = LTRIM(RTRIM(@SkuCode));

    IF EXISTS (SELECT 1 FROM dbo.StockWebhookInbound WHERE EventId = @EventId)
    BEGIN
        SELECT ResultCode, EventType, SkuCode, Quantity, OnHand, ErrorMessage
        FROM dbo.StockWebhookInbound
        WHERE EventId = @EventId;
        RETURN;
    END

    IF @NormalizedType NOT IN (N'sale.created', N'return.created')
    BEGIN
        SELECT 400 AS ResultCode, @EventType AS EventType, @NormalizedSku AS SkuCode, @Quantity AS Quantity,
               CAST(NULL AS INT) AS OnHand, N'eventType must be sale.created or return.created.' AS ErrorMessage;
        RETURN;
    END

    IF @Quantity IS NULL OR @Quantity < 1
    BEGIN
        SELECT 400 AS ResultCode, @NormalizedType AS EventType, @NormalizedSku AS SkuCode, @Quantity AS Quantity,
               CAST(NULL AS INT) AS OnHand, N'quantity must be at least 1.' AS ErrorMessage;
        RETURN;
    END

    SELECT
        @MatchCount = COUNT(*),
        @SizeId = MIN(ps.SizeId)
    FROM dbo.V_ProductSize ps
    WHERE ps.SizeId IS NOT NULL
      AND LTRIM(RTRIM(ps.ProductCode)) + N'_' + LTRIM(RTRIM(ps.Size)) = @NormalizedSku;

    IF @MatchCount = 0
    BEGIN
        SET @ResultCode = 404;
        SET @ErrorMessage = N'SKU not found.';
        INSERT INTO dbo.StockWebhookInbound (EventId, EventType, SkuCode, Quantity, OnHand, ResultCode, ErrorMessage)
        VALUES (@EventId, @NormalizedType, @NormalizedSku, @Quantity, NULL, @ResultCode, @ErrorMessage);
        SELECT @ResultCode AS ResultCode, @NormalizedType AS EventType, @NormalizedSku AS SkuCode, @Quantity AS Quantity,
               CAST(NULL AS INT) AS OnHand, @ErrorMessage AS ErrorMessage;
        RETURN;
    END

    IF @MatchCount > 1
    BEGIN
        SET @ResultCode = 409;
        SET @ErrorMessage = N'SKU matches more than one SizeId.';
        INSERT INTO dbo.StockWebhookInbound (EventId, EventType, SkuCode, Quantity, OnHand, ResultCode, ErrorMessage)
        VALUES (@EventId, @NormalizedType, @NormalizedSku, @Quantity, NULL, @ResultCode, @ErrorMessage);
        SELECT @ResultCode AS ResultCode, @NormalizedType AS EventType, @NormalizedSku AS SkuCode, @Quantity AS Quantity,
               CAST(NULL AS INT) AS OnHand, @ErrorMessage AS ErrorMessage;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @NormalizedType = N'sale.created'
        BEGIN
            SELECT TOP (1) @CurrencyId = c.CurrencyId FROM dbo.Currencies c ORDER BY c.CurrencyId;
            SELECT TOP (1) @PaymentTypeId = pt.PaymentTypeId FROM dbo.PaymentTypes pt ORDER BY pt.PaymentTypeId;

            INSERT INTO dbo.Sales (
                UserId, CurrencyId, Customer, PaymentTypeId, Note, OrderRequestId,
                DiscountPercent, DiscountFixedAmount, CreatedAt
            )
            VALUES (
                @UserId, @CurrencyId, N'ecommerce', @PaymentTypeId, N'ecommerce', NULL,
                0, 0, GETDATE()
            );
            SET @SaleId = SCOPE_IDENTITY();

            INSERT INTO dbo.SaleLines (SaleId, SizeId, Product, Quantity, UnitPrice, ListPrice)
            VALUES (@SaleId, @SizeId, @NormalizedSku, @Quantity, 0, 0);
        END
        ELSE
        BEGIN
            INSERT INTO dbo.StockEntries (SizeId, Quantity, UserId, Note)
            VALUES (@SizeId, @Quantity, @UserId, N'ecommerce');
        END

        SELECT @OnHand = ISNULL((SELECT StockQty FROM dbo.V_SizeStock WHERE SizeId = @SizeId), 0);

        INSERT INTO dbo.StockWebhookInbound (EventId, EventType, SkuCode, Quantity, OnHand, ResultCode, ErrorMessage)
        VALUES (@EventId, @NormalizedType, @NormalizedSku, @Quantity, @OnHand, 200, NULL);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @ResultCode = 500;
        SET @ErrorMessage = ERROR_MESSAGE();
        IF NOT EXISTS (SELECT 1 FROM dbo.StockWebhookInbound WHERE EventId = @EventId)
            INSERT INTO dbo.StockWebhookInbound (EventId, EventType, SkuCode, Quantity, OnHand, ResultCode, ErrorMessage)
            VALUES (@EventId, @NormalizedType, @NormalizedSku, @Quantity, NULL, @ResultCode, @ErrorMessage);
        SELECT @ResultCode AS ResultCode, @NormalizedType AS EventType, @NormalizedSku AS SkuCode, @Quantity AS Quantity,
               CAST(NULL AS INT) AS OnHand, @ErrorMessage AS ErrorMessage;
        RETURN;
    END CATCH

    SELECT 200 AS ResultCode, @NormalizedType AS EventType, @NormalizedSku AS SkuCode, @Quantity AS Quantity,
           @OnHand AS OnHand, CAST(NULL AS NVARCHAR(400)) AS ErrorMessage;
END
GO
/****** Object:  StoredProcedure [dbo].[API_WebHook_OutboundDequeue]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_WebHook_OutboundDequeue]
    @Take INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH cte AS (
        SELECT TOP (@Take) OutboundId
        FROM dbo.StockWebhookOutbound WITH (UPDLOCK, READPAST, ROWLOCK)
        WHERE Status = N'Pending'
          AND Attempts < 3
        ORDER BY OutboundId
    )
    SELECT
        o.OutboundId,
        o.EventId,
        o.EventType,
        o.SizeId,
        o.SkuCode,
        o.Quantity,
        o.OnHand,
        o.CreatedAt,
        o.Attempts
    FROM dbo.StockWebhookOutbound o
    INNER JOIN cte ON cte.OutboundId = o.OutboundId
    ORDER BY o.OutboundId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_WebHook_OutboundMarkAttempt]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_WebHook_OutboundMarkAttempt]
    @OutboundId BIGINT,
    @Error NVARCHAR(4000),
    @Failed BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.StockWebhookOutbound
    SET Attempts = Attempts + 1,
        LastError = @Error,
        Status = CASE WHEN @Failed = 1 THEN N'Failed' ELSE Status END
    WHERE OutboundId = @OutboundId;
END

GO
/****** Object:  StoredProcedure [dbo].[API_WebHook_OutboundMarkSent]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_WebHook_OutboundMarkSent]
    @OutboundId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.StockWebhookOutbound
    SET Status = N'Sent',
        SentAt = SYSUTCDATETIME(),
        LastError = NULL
    WHERE OutboundId = @OutboundId;
END
GO
/****** Object:  StoredProcedure [dbo].[API_WebHook_StockSnapshot]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[API_WebHook_StockSnapshot]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LTRIM(RTRIM(ps.ProductCode)) + N'_' + LTRIM(RTRIM(ps.Size)) AS SkuCode,
        ISNULL(ss.StockQty, 0) AS Quantity
    FROM dbo.V_ProductSize ps
    LEFT JOIN dbo.V_SizeStock ss ON ss.SizeId = ps.SizeId
    WHERE ps.SizeId IS NOT NULL
      AND ps.Size IS NOT NULL
      AND LTRIM(RTRIM(ISNULL(ps.ProductCode, N''))) <> N''
    ORDER BY SkuCode;
END
GO
/****** Object:  StoredProcedure [dbo].[DelSize]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[DelSize] (@sizeId int = -1)

as

--select * from DeletedSize

insert into DeletedSize(SizeId,VariantId,Size,Barcode,SilinmeTarihi)
select SizeId,VariantId,Size,Barcode, SilinmeTarihi = GETDATE() from Size where SizeId = @sizeId

delete from Size where SizeId = @sizeId
GO
/****** Object:  StoredProcedure [dbo].[ExportGridColumn]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 create PROC [dbo].[ExportGridColumn](@GridId int, @source varchar(max))
 as
 
 if (@source = 'TEST')
 begin
	delete from confexpert.dbo.GridColumn  where GridId = @GridId

	insert into confexpert.dbo.GridColumn  (GridId	,ColumnName	,Caption	,FormatAsNumber	,Width	,Bold	,Centered	,LookUpId	,Tooltip	,Position	,Visible	,Expression	,Summary)
	select GridId	,ColumnName	,Caption	,FormatAsNumber	,Width	,Bold	,Centered	,LookUpId	,Tooltip	,Position	,Visible	,Expression	,Summary from confexperttest.dbo.GridColumn  where GridId = @GridId
 end
 else if (@source = 'PRODUCTION')
 begin
      delete from confexperttest.dbo.GridColumn   where GridId = @GridId

	insert into confexperttest.dbo.GridColumn  (GridId	,ColumnName	,Caption	,FormatAsNumber	,Width	,Bold	,Centered	,LookUpId	,Tooltip	,Position	,Visible	,Expression	,Summary)
	select GridId	,ColumnName	,Caption	,FormatAsNumber	,Width	,Bold	,Centered	,LookUpId	,Tooltip	,Position	,Visible	,Expression	,Summary from confexpert.dbo.GridColumn  where GridId = @GridId
 end
GO
/****** Object:  StoredProcedure [dbo].[GetColor]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetColor]
as
select * from Color
GO
/****** Object:  StoredProcedure [dbo].[GetColumnsByTable]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[GetColumnsByTable] (@TableName varchar(max) = 'AksesuarHareket')
as
 
declare @tmp varchar(MAX) = ''
select @tmp = @tmp + '['+COLUMN_NAME + '], ' from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and column_Name not in ('InsertedOn')

select SUBSTRING(@tmp, 0, LEN(@tmp)) ColumnNames

GO
/****** Object:  StoredProcedure [dbo].[GetFabricMaterial]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetFabricMaterial] as
select * from FabricMaterial
 
GO
/****** Object:  StoredProcedure [dbo].[GetFullProductCodes]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetFullProductCodes]
as

select 

 StyleName
,ProductColorName
,FullProductCode 
,VariantId
from 
	v_FullProductCode v

	/*
select 
distinct 
s.StyleName
,[PRODUCT COLOR NAME] = case when mc.ColorName = sc.ColorName then mc.ColorName else  mc.ColorName + isnull('/' + sc.ColorName,'')	end
,FullProductCode = mcat.MainCategoryCode + '.' + pg.ProductGroupCode + tg.TypeGenderCode + '_' + pc.ProductCategoryCode +  FORMAT(a.ArticleId, '0000') + '_' + mf.MainFabricCode + fm.FabricMaterialCode + mc.ColorCode + sc.ColorCode --[MODEL CODE] + '_' + [FABRIC + COLOR CODE]
from Style s
left join MainCategory mcat on mcat.MainCategoryId = s.MainCategoryId
left join WebCategory wcat on wcat.WebCategoryId = s.WebCategoryId
left join ProductGroup pg on pg.ProductGroupId = s.ProductGroupId
left join TypeGender tg on tg.TypeGenderId = s.TypeGenderId
left join ProductCategory pc on pc.ProductCategoryId = s.ProductCategoryId


left join Article a on a.StyleId = s.StyleId
left join MainFabric mf on mf.MainFabricId = a.MainFabricId
left join Season sea on sea.SeasonId = a.SeasonId
left join Variant v on v.ArticleId = a.ArticleId
left join FabricMaterial fm on fm.FabricMaterialId = a.FabricMaterialId

left join Size si on si.VariantId = v.VariantId
left join Color mc on mc.ColorId = v.MainColorId
left join Color sc on sc.ColorId = v.SecondaryColorId
*/
GO
/****** Object:  StoredProcedure [dbo].[GetGridColumns]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[GetGridColumns](@GridId int = 56)
as

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

select 
	 GridColumnId
	,GridId
	,ColumnName
	,Caption
	,Tooltip
	,case when visible = 0 then null else Position end Position
	,Visible
	,Bold
	,Centered
	,Width
	,FormatAsNumber
	,Summary
	,LookUpId
	,Expression	
from 
	GridColumn where GridId = @GridId
	order by visible desc, Position
GO
/****** Object:  StoredProcedure [dbo].[GetLookups]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetLookups]
as
select 'Color' Lookup
--union select 'NameCategory'
union select 'MainCategory'
union select 'WebCategory'
union select 'WebCategory'
union select 'ProductGroup'
union select 'TypeGender'
union select 'ProductCategory'
union select 'SizeChart'
union select 'SizeSet'
union select 'MainFabric'
union select 'ProductGroup'
union select 'ProductGroupWeb'
union select 'ProductCategoryWeb'
union select 'FabricMaterial'
union select 'ModelReference'
union select 'ModelReference'
union select 'Season'
union select 'WebSizeType'
union select 'Year'
order by 1
GO
/****** Object:  StoredProcedure [dbo].[GetMainCategory]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetMainCategory]
as
select * from MainCategory
GO
/****** Object:  StoredProcedure [dbo].[GetMainFabric]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 create proc [dbo].[GetMainFabric]
 as
 select * from MainFabric
GO
/****** Object:  StoredProcedure [dbo].[GetModelReference]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[GetModelReference]
as
select * from ModelReference
GO
/****** Object:  StoredProcedure [dbo].[GetNameCategory]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetNameCategory]
as
select * from NameCategory
GO
/****** Object:  StoredProcedure [dbo].[GetPriceList]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetPriceList]
as

select PriceListId,Caption,InsertedOn into #x from PriceList
union
select 0 , 'ACTIVE PRICES' , getdate()

select * from #x order by case when PriceListId = 0 then  1e9 else PriceListId  end desc

select 
     PriceListId = 0
	,s.StyleId
	,s.StyleName
	,Category = mc.MainCategoryName
	,ProductName
	 
	,PriceEUR
	,PriceUSD
	,PriceTL
from Style s
left join MainCategory mc on mc.MainCategoryId = s.MainCategoryId

union

select 
     d.PriceListId 
	,s.StyleId
	,s.StyleName
	,Category = mc.MainCategoryName
	,ProductName
	 
	,d.PriceEUR
	,d.PriceUSD
	,d.PriceTL
from 
	PriceListDetail d 
inner join PriceList pl on pl.PriceListId = d.PriceListId
left join Style s on s.StyleId = d.StyleId
left join MainCategory mc on mc.MainCategoryId = s.MainCategoryId



 
GO
/****** Object:  StoredProcedure [dbo].[GetProductCategory]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetProductCategory]
as
select * from ProductCategory
 
GO
/****** Object:  StoredProcedure [dbo].[GetProductCategoryWeb]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 create proc [dbo].[GetProductCategoryWeb]
 as
 select * from ProductCategoryWeb
GO
/****** Object:  StoredProcedure [dbo].[GetProductGroup]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetProductGroup]
as
select * from ProductGroup
 
GO
/****** Object:  StoredProcedure [dbo].[GetProductGroupWeb]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

   create proc [dbo].[GetProductGroupWeb]
   as
   select * from ProductGroupWeb
GO
/****** Object:  StoredProcedure [dbo].[GetProductList]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetProductList] as

select 

	 VariantId
	,Style = StyleName
	,ProductName	 
	,ProductCode	
	,MainCategory = MainCategoryName
	,ProductGroup = ProductGroupName
	,TypeGender = TypeGenderName
	,ProductCategory = ProductCategoryName
	,Season = SeasonCode 	
	,MainFabric = MainFabricName
	,FabricMaterial = FabricMaterialName	
	,MainColor = MainColorName
	,SecondaryColor = SecondaryColorName
from v_Product
Order by StyleId,ArticleId,VariantId
--2,3,4,5,6,7
	
	--select * from v_product
	 
GO
/****** Object:  StoredProcedure [dbo].[GetProducts2]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[GetProducts2]
AS
SELECT
     StyleId
    ,ArticleCount = COUNT(DISTINCT a.ArticleId)
    ,VariantCount = COUNT(DISTINCT v.VariantId)
    ,SizeCount = COUNT(DISTINCT s.SizeId)
INTO #ac
FROM Article a
LEFT JOIN Variant v ON v.ArticleId = a.ArticleId
LEFT JOIN Size s ON s.VariantId = v.VariantId
GROUP BY StyleId;

SELECT
     ArticleId
    ,VariantCount = COUNT(DISTINCT v.VariantId)
    ,SizeCount = COUNT(DISTINCT s.SizeId)
INTO #vc
FROM Variant v
LEFT JOIN Size s ON s.VariantId = v.VariantId
GROUP BY ArticleId;

SELECT
     VariantId
    ,SizeCount = COUNT(DISTINCT SizeId)
INTO #sc
FROM Size
GROUP BY VariantId;

SELECT DISTINCT
     VariantId
    ,VariantCode = ProductCode
INTO #variantCode
FROM dbo.V_ProductSize;

SELECT
     s.StyleId
    ,StyleName
    ,MainCategoryId
    ,WebCategoryId
    ,ProductGroupId
    ,TypeGenderId
    ,ProductCategoryId
    ,SizeChartId
    ,SizeSetId
    ,ProductName
    ,ProductDescription
    ,ProductFeatures
    ,CareInstructions
    ,UrunAdi
    ,UrunAciklamasi
    ,UrunOzellikleri
    ,YikamaTalimatlari
    ,NomeDelProdotto
    ,DescrizioneDelProdotto
    ,CaratteristicheDelProdotto
    ,IstruzioniPerLaCura
    ,PriceTL
    ,PriceEUR
    ,PriceUSD
    ,s.MadeInItalyLogo
    ,ac.ArticleCount
    ,ac.VariantCount
    ,ac.SizeCount
FROM Style s
LEFT JOIN #ac ac ON ac.StyleId = s.StyleId
ORDER BY s.StyleId;

SELECT
     a.*
    ,vc.VariantCount
    ,vc.SizeCount
FROM Article a
LEFT JOIN #vc vc ON vc.ArticleId = a.ArticleId
ORDER BY a.ArticleId;

SELECT
     v.*
    ,sc.SizeCount
    ,vc.VariantCode
FROM Variant v
LEFT JOIN #sc sc ON sc.VariantId = v.VariantId
LEFT JOIN #variantCode vc ON vc.VariantId = v.VariantId
ORDER BY v.VariantId;

SELECT s.*
FROM dbo.Size s
LEFT JOIN dbo.V_ProductSize ps ON ps.SizeId = s.SizeId
LEFT JOIN dbo.Style st ON st.StyleId = ps.StyleId
LEFT JOIN dbo.V_SizeSetSize vss
    ON vss.SizeSetId = st.SizeSetId
   AND vss.SizeValue = s.Size
ORDER BY s.VariantId, vss.Pos, s.Size;
GO
/****** Object:  StoredProcedure [dbo].[GetSeason]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetSeason]
as
select * from Season
GO
/****** Object:  StoredProcedure [dbo].[GetSizeChart]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetSizeChart]
as
select * from  SizeChart
GO
/****** Object:  StoredProcedure [dbo].[GetSizeSet]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 create proc [dbo].[GetSizeSet]
 as
 select * from SizeSet
GO
/****** Object:  StoredProcedure [dbo].[GetSKU]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[GetSKU]
AS
SELECT *
INTO #x
FROM dbo.V_SKU;

WITH d AS
(
    SELECT DISTINCT
        [STYLE NAME],
        [PRODUCT COLOR NAME]
    FROM #x
)
SELECT
    [STYLE NAME],
    STRING_AGG([PRODUCT COLOR NAME], ';') WITHIN GROUP (ORDER BY [PRODUCT COLOR NAME]) AS [COLOR VARIANTS OF STYLE]
INTO #Colors
FROM d
GROUP BY [STYLE NAME];

WITH d AS
(
    SELECT DISTINCT
        [STYLE NAME],
        SizeSetId,
        [SIZE]
    FROM #x
)
SELECT
    [STYLE NAME],
    d.SizeSetId,
    STRING_AGG([SIZE], ';') WITHIN GROUP (ORDER BY v.Pos, d.[SIZE]) AS [SIZE RANGE OF STYLE]
INTO #sizes
FROM d
INNER JOIN V_SizeSetSize v
    ON v.SizeSetId = d.SizeSetId
   AND v.SizeValue = d.[SIZE]
GROUP BY [STYLE NAME], d.SizeSetId;

SELECT
     s.[BARCODE GS1/EAN]
    ,s.[ART. #]
    ,s.[STYLE NAME]
    ,s.[PRODUCT NAME]
    ,s.[PRODUCT CODE]
    ,s.SIZE
    ,s.[MAIN CATEGORY]
    ,s.[WEB CATEGORY]
    ,s.[PRODUCT GROUP]
    ,s.[TYPE / GENDER]
    ,s.[PRODUCT CATEGORY]
    ,s.[SEASON]
    ,s.[MAIN FABRIC]
    ,s.[MAIN COLOR]
    ,s.[SECONDARY COLOR]
    ,s.[PRODUCT COLOR NAME]
    ,s.[MODEL CODE]
    ,s.[FABRIC + COLOR CODE]
    ,s.[FULL PRODUCT CODE]
    ,s.[SKU CODE]
    ,[BARCODE GS1/EAN ] = s.[BARCODE GS1/EAN]
    ,c.[COLOR VARIANTS OF STYLE]
    ,si.[SIZE RANGE OF STYLE]
    ,s.[MAIN PHOTO]
    ,s.[PHOTO 2]
    ,s.[PHOTO 3]
    ,s.[PHOTO 4]
    ,s.[PHOTO 5]
    ,s.[PHOTO 6]
    ,s.[VIDEO]
    ,s.[EXTRA MEDIA]
    ,s.[PRODUCT TITLE]
    ,s.[PRODUCT DESCRIPTION]
    ,s.[PRODUCT FEATURES]
    ,s.[CARE INSTRUCTIONS]
    ,s.[ÜRÜN ADI]
    ,s.[ÜRÜN AÇIKLAMASI]
    ,s.[ÜRÜN ÖZELLİKLERİ]
    ,s.[YIKAMA TALİMATLARI]
    ,s.[TITOLO DEL PRODOTTO]
    ,s.[DESCRIZIONE DEL PRODOTTO]
    ,s.[CARATTERISTICHE DEL PRODOTTO]
    ,s.[ISTRUZIONI PER LA CURA]
    ,s.[PRODUKTTITEL]
    ,s.[PRODUKT BESCHREIBUNG]
    ,s.[PRODUKT MERKMALE]
    ,s.[PFLEGEHINWEISE]
    ,s.[ALSO IN THE PHOTO 1]
    ,s.[ALSO IN THE PHOTO 2]
    ,s.[ALSO IN THE PHOTO 3]
    ,s.[ALSO IN THE PHOTO 4]
    ,s.[ALSO IN THE PHOTO 5]
    ,s.[RELATED PRODUCTS 1]
    ,s.[RELATED PRODUCTS 2]
    ,s.[RELATED PRODUCTS 3]
    ,s.[RELATED PRODUCTS 4]
    ,s.[RELATED PRODUCTS 5]
    ,s.[MAIN CATEGORY ID]
    ,s.[WEB CATEGORY ID]
    ,s.[PRODUCT GROUP ID]
    ,s.[TYPE/GRENDER ID]
    ,s.[PRODUCT CATEGORY ID]
    ,s.[ATTRIBUTES (EX-PRODUCT CAT) ID]
    ,s.[NEW IN]
    ,s.[BESTSELLERS]
    ,s.[SHOP THE LOOK]
    ,s.[COMPETITION]
    ,s.[OUTLET]
    ,s.[TBF X SANMARCO]
    ,[TOTAL CATEGORIES] = (
            SELECT STRING_AGG(val, ';') WITHIN GROUP (ORDER BY min_ord)
            FROM (
                SELECT val, MIN(ord) AS min_ord
                FROM (VALUES
                    (1, CAST(s.[MAIN CATEGORY ID] AS VARCHAR(50))),
                    (2, CAST(s.[WEB CATEGORY ID] AS VARCHAR(50))),
                    (3, CAST(s.[PRODUCT GROUP ID] AS VARCHAR(50))),
                    (4, CAST(s.[PRODUCT CATEGORY ID] AS VARCHAR(50))),
                    (5, CAST(s.[NEW IN] AS VARCHAR(50))),
                    (6, CAST(s.BESTSELLERS AS VARCHAR(50))),
                    (7, CAST(s.[SHOP THE LOOK] AS VARCHAR(50))),
                    (8, CAST(s.COMPETITION AS VARCHAR(50))),
                    (9, CAST(s.OUTLET AS VARCHAR(50))),
                    (10, CAST(s.[TBF X SANMARCO] AS VARCHAR(50))),
                    (11, CAST(s.[ADDITIONAL (MANUAL) CAT.] AS VARCHAR(50))),
                    (12, CAST(s.[THE AFTER COLLECTION] AS VARCHAR(50)))
                ) AS t(ord, val)
                WHERE NULLIF(val, '') IS NOT NULL
                GROUP BY val
            ) v
        )
    ,s.[ADDITIONAL (MANUAL) CAT.]
    ,s.[VARIANTS]
    ,s.[PRICE EURO]
    ,s.[PRICE TL]
    ,s.[PRICE USD]
    ,s.[INITIAL STOCK QTY]
    ,s.[SOLD QTY]
    ,s.[IN-STOCK QTY]
    ,s.[PUBLISH]
    ,s.[MODEL REFERENCE]
    ,s.[SIZE CHART REFERENCE]
    ,s.[MADE IN ITALY LOGO]
    ,s.[UPDATE]
    ,s.[NOTES]
    ,s.[THE AFTER COLLECTION]
    ,s.[MODEL SIZE INFO]
    ,[SKU ID] = s.SizeId
FROM #x s
LEFT JOIN #Colors c ON c.[STYLE NAME] = s.[STYLE NAME]
LEFT JOIN #sizes si ON si.[STYLE NAME] = s.[STYLE NAME]
ORDER BY s.StyleId;
GO
/****** Object:  StoredProcedure [dbo].[GetSKU_ModelReference]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[GetSKU_ModelReference]
AS
SELECT DISTINCT
     [STYLE NAME]
    ,[PRODUCT NAME]
    ,[PRODUCT CODE]
    ,[MAIN COLOR]
    ,[SECONDARY COLOR]
    ,[FULL PRODUCT CODE]
    ,[MODEL REFERENCE]
FROM dbo.V_SKU;
SELECT
     [MODEL NAME] = ModelName
    ,[MODEL REFERENCE] = WebSiteCode
    ,[MODEL GENDER] = ModelGender
    ,[MODEL AGE] = ModelAge
    ,[MODEL ORIGIN] = ModelOrigin
    ,[MODEL AGENCY] = ModelAgency
    ,[CAPTION] = Caption
    ,[HEIGHT] = CONCAT(HeightCm, CASE WHEN HeightCm IS NULL THEN '' ELSE ' CM' END)
    ,[WEIGHT] = CONCAT(WeightKg, CASE WHEN WeightKg IS NULL THEN '' ELSE ' KM' END)
    ,[CHEST] = CONCAT(ChestCm, CASE WHEN ChestCm IS NULL THEN '' ELSE ' CM' END)
    ,[WAIST] = CONCAT(WaistCm, CASE WHEN WaistCm IS NULL THEN '' ELSE ' CM' END)
    ,[HIPS] = CONCAT(HipsCm, CASE WHEN HipsCm IS NULL THEN '' ELSE ' CM' END)
    ,[SHOE SIZE] = CONCAT(ShoeSizeEU, CASE WHEN ShoeSizeEU IS NULL THEN '' ELSE ' EU' END)
FROM dbo.ModelReference;
GO
/****** Object:  StoredProcedure [dbo].[GetSKUMapping]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetSKUMapping] as


--select 
-- p.SizeId
--,p.VariantId
--,p.ArticleId
--,p.StyleId
--,p.Barcode
--,ErpSKU = p.SKU
--,p.ProductCode
--,p.MainCategoryName
--,p.MainColorCode
--,p.ProductGroupCode
--,p.ProductGroupName
--,p.TypeGenderCode
--,p.TypeGenderName
--,p.ProductCategoryCode
--,ArticleCode = FORMAT(p.StyleId, '0000')
--,p.ProductCategoryName
--,p.SeasonCode
--,p.MainFabricCode
--,p.MainFabricName
--,p.FabricMaterialCode
--,p.FabricMaterialName
--,p.MainCategoryCode
--,p.MainColorName
--,p.SecondaryColorName
--,ColorCode =  p.MainColorCode + p.SecondaryColorCode
--,p.Size

----,WebSiteSKU = ss.SKU
--from V_ProductSize p 
--left join SiteSKU ss on p.SKU = ss.SKU
--where   p.SizeId not in (

--select 
-- p.SizeId 

----,WebSiteSKU = ss.SKU
--from V_ProductSize p 
--left join SiteSKU ss on p.SKU = ss.SKU
--where   p.StyleId < 114
--and ss.SKU is not null
--and p.StyleId not in (22, 23, 24, 25, 26, 57, 58, 59, 60, 61)
--)




select
 ss.SKU
,Part1 =  dbo.[String.Split](ss.SKU,'.' , 0)
,Part2 = replace( dbo.[String.Split](ss.SKU,'_' , 0) , dbo.[String.Split](ss.SKU,'.' , 0) + '.' , '')
,Part3 = dbo.[String.Split](ss.SKU,'_' , 1)
,Part4 = dbo.[String.Split](ss.SKU,'_' , 2)
,Part5 = dbo.[String.Split](ss.SKU,'_' , 3)
from SiteSKU ss
left join V_ProductSize p on p.SKU = ss.SKU
where  p.SizeId is null and durum is null


 
select 
 p.SizeId
,p.VariantId
,p.ArticleId
,p.StyleId
,p.Barcode
,ErpSKU = p.SKU
,p.ProductCode
,p.MainCategoryName
,p.MainColorCode
,p.ProductGroupCode
,p.ProductGroupName
,p.TypeGenderCode
,p.TypeGenderName
,p.ProductCategoryCode
,ArticleCode = FORMAT(p.StyleId, '0000')
,p.ProductCategoryName
,p.SeasonCode
,p.MainFabricCode
,p.MainFabricName
,p.FabricMaterialCode
,p.FabricMaterialName
,p.MainCategoryCode
,p.MainColorName
,p.SecondaryColorName
,ColorCode =  p.MainColorCode + p.SecondaryColorCode
,p.Size

--,WebSiteSKU = ss.SKU
from V_ProductSize p 
left join SiteSKU ss on p.SKU = ss.SKU
where   p.StyleId < 114
and ss.SKU is null
and p.StyleId not in (22, 23, 24, 25, 26, 57, 58, 59, 60, 61)
 

select [SKU CODE], * from DataCsmAll3




  /*

  
select * from SiteSKU where SKU like '%soc%'

select * from v_productSize where sku like 'A.RACAU_SOC%0018_NYL00003XBST1_3%-4%'
select * from v_productSize where sku like 'A.RACAU_SOC%0018_NYL00003XBST4_3%-4%'
select * from v_productSize where sku like 'A.RACAU_SOC%0018_NYL00003XBST6_3%-4%'

select * from SiteSKU where SKU = 'A.RACAU_SOCS0018_NYL00003XBST2_36-44'
								   A.RACAU_SOCS0018_NYL00003XBST1_36-44




  select 
 p.SizeId
,p.ProductCode
,p.MainCategoryName
,p.ProductGroupName
,p.TypeGenderName
,p.ProductCategoryName
,p.SeasonCode
,p.MainFabricName
,p.FabricMaterialName
,p.MainCategoryCode
,p.MainColorName
,p.SecondaryColorName
,ErpSKU = p.SKU
,WebSiteSKU = ss.SKU
from V_ProductSize p 
inner join SiteSKU ss
on p.SKU = ss.SKU
where  p.StyleId < 103 and p.ArticleId < 126

*/
GO
/****** Object:  StoredProcedure [dbo].[GetTableByColumns]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetTableByColumns](@CommaSeperatedColumns varchar(max) = 'Bold,Caption,Centered,ColumnName,Expression,FormatAsNumber,GridColumnId,GridFullName,LookUpId,Position,Summary,Tooltip,Visible,Width')
    as
         
    SELECT p1.Table_Name TableName,
           (SELECT COLUMN_Name + ','  FROM INFORMATION_SCHEMA.COLUMNS p2 WHERE p2.Table_Name = p1.Table_Name ORDER BY COLUMN_NAME FOR XML PATH('') ) AS Columns
    into #t
    FROM INFORMATION_SCHEMA.COLUMNS p1     
	GROUP BY Table_Name 

    select distinct TableName from #t where Columns = @CommaSeperatedColumns + ','
    and tableName not like '[_]%'
GO
/****** Object:  StoredProcedure [dbo].[GetTypeGender]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetTypeGender]
as
select * from TypeGender
 
GO
/****** Object:  StoredProcedure [dbo].[GetUser]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[GetUser] (@userName varchar(100) , @pass varchar(100))
as

select
	 UserId = convert(int,1)
	,UserName = 'ck'
	,Name = 'Cemal Karabel'
	,Email = 'cemal.karabel@karbel.com'
where @userName = 'ck' and @pass = 'ck'


GO
/****** Object:  StoredProcedure [dbo].[GetWebCategory]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetWebCategory]
as
select * from WebCategory
 
GO
/****** Object:  StoredProcedure [dbo].[GetWebSizeType]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetWebSizeType]
as
select * from WebSizeType
 
GO
/****** Object:  StoredProcedure [dbo].[GetYear]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[GetYear]
as
select * from Year
GO
/****** Object:  StoredProcedure [dbo].[InsGrid]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[InsGrid]( @GridName varchar(max))
as
Insert into Grid (Name)
select @GridName

select  'gv.SetID(' + convert(varchar(100),SCOPE_IDENTITY()) + ');' NewGridId 
GO
/****** Object:  StoredProcedure [dbo].[InsLogExport]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InsLogExport] 
@FormName varchar(500) = '',
@GridName varchar(50) = '',
@Format varchar(5) = '',
@UserId int
AS
--insert LogExport(FormName, GridName, Format, UserId, InsertedOn) values (@FormName, @GridName, @Format, @UserId, GETDATE())
GO
/****** Object:  StoredProcedure [dbo].[InsLogForm]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[InsLogForm]( @UserId int,@FormType varchar(max))
as
--insert into LogForm(UserId,FormType)
--values (@UserId,@FormType)


GO
/****** Object:  StoredProcedure [dbo].[Reseed]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[Reseed]
as

declare @x int 
select @x = max(StyleId) from Style
DBCC CHECKIDENT ('Style', RESEED, @x );
GO
/****** Object:  StoredProcedure [dbo].[SavePriceList]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[SavePriceList] 
 @master xml = '',
 @detail xml = ''
 as
  

 create table #master(
	PriceListId int ,
	Caption varchar(max) )

	create table #detail(
	PriceListId int ,
	StyleId int ,
	PriceEUR decimal(18,2),
	PriceUSD decimal(18,2),
	PriceTL decimal(18,2))

 DECLARE @x XML
declare @idoc int

set @x = @master
exec sp_xml_preparedocument @idoc output, @x
insert into #master select * from openxml(@idoc, '/MyData/Table', 2) with #master
exec sp_xml_removedocument @idoc


set @x = @detail
exec sp_xml_preparedocument @idoc output, @x
insert into #detail select * from openxml(@idoc, '/MyData/Table', 2) with #detail
exec sp_xml_removedocument @idoc

select * from #master
select * from #detail

update p set Caption = m.Caption from PriceList p inner join #master m on p.PriceListId = m.PriceListId
where m.PriceListId > 0

insert into PriceList (Caption,InsertedOn)
select Caption,getdate() from #master where PriceListId = 0

declare @id int
select @id = SCOPE_IDENTITY()

insert into PriceListDetail (PriceListId,StyleId,PriceEUR,PriceUSD,PriceTL)
select @id,StyleId,PriceEUR,PriceUSD,PriceTL from #detail

update PriceList set Caption = concat('Price List #' , PriceListId) where PriceListId = @id and Caption = 'ACTIVE PRICES'
GO
/****** Object:  StoredProcedure [dbo].[SaveSKU]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[SaveSKU] 
 @xml xml = '<MyData><Table><SizeId>17</SizeId><IN-STOCK_x0020_QTY>1</IN-STOCK_x0020_QTY></Table><Table><SizeId>18</SizeId><IN-STOCK_x0020_QTY>2</IN-STOCK_x0020_QTY></Table><Table><SizeId>19</SizeId><IN-STOCK_x0020_QTY>3</IN-STOCK_x0020_QTY></Table><Table><SizeId>1</SizeId></Table><Table><SizeId>3</SizeId></Table><Table><SizeId>4</SizeId></Table></MyData>'
 as
  

 create table #x(
	SizeId int ,
	[IN-STOCK QTY] int ,
	[PUBLISH] varchar(100)
	)

declare @idoc int
exec sp_xml_preparedocument @idoc output, @xml
insert into #x select * from openxml(@idoc, '/MyData/Table', 2) with #x
exec sp_xml_removedocument @idoc


select v.VariantId,Publish = case when x.[PUBLISH] = '1' then CONVERT(bit,1) else CONVERT(bit,0) end
into #v 
from   
Size s 
inner join #x x on s.SizeId = x.SizeId
inner join Variant v on s.VariantId		= v.VariantId
--inner join Article a on v.ArticleId = a.ArticleId
 
update v set v.Publish = vv.Publish from Variant v
inner join #v vv on v.VariantId = vv.VariantId


update s set InStockQty = x.[IN-STOCK QTY] from Size s inner join #x x on
s.SizeId = x.SizeId

select x.* from   Size s inner join #x x on
s.SizeId = x.SizeId
GO
/****** Object:  StoredProcedure [dbo].[UpdLogPrg]    Script Date: 30.08.2026 06:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 
CREATE PROC [dbo].[UpdLogPrg]
@UserId int = 17,
@Version varchar(50) = '',
@DataFileSize int,
@Sure1 decimal(18, 2),
@Sure2 decimal(18, 2)
AS

--insert into LogPrg (DataFileSize, Sure1, Sure2, Version, WhoAmI)
select @DataFileSize, @Sure1, @Sure2, @Version, @UserId


GO
