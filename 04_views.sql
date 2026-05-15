/*1. SQL Pass-Through Views (Exact Copies - NOT using SELECT ):

-----Dimension Table Pass-Through Views:-----*/

-- Pass-through view for DIM_DATE
--DROP VIEW "V_DIM_DATE";
CREATE SECURE VIEW "V_DIM_DATE" AS
SELECT 
    DATE_PKEY,
    DATE,
    FULL_DATE_DESC,
    DAY_NUM_IN_WEEK,
    DAY_NUM_IN_MONTH,
    DAY_NUM_IN_YEAR,
    DAY_NAME,
    DAY_ABBREV,
    WEEKDAY_IND,
    US_HOLIDAY_IND,
    /*<COMPANYNAME>*/_HOLIDAY_IND,  -- Use the actual column name from table definition
    MONTH_END_IND,
    WEEK_BEGIN_DATE_NKEY,
    WEEK_BEGIN_DATE,
    WEEK_END_DATE_NKEY,
    WEEK_END_DATE,
    WEEK_NUM_IN_YEAR,
    MONTH_NAME,
    MONTH_ABBREV,
    MONTH_NUM_IN_YEAR,
    YEARMONTH,
    QUARTER,
    YEARQUARTER,
    YEAR,
    FISCAL_WEEK_NUM,
    FISCAL_MONTH_NUM,
    FISCAL_YEARMONTH,
    FISCAL_QUARTER,
    FISCAL_YEARQUARTER,
    FISCAL_HALFYEAR,
    FISCAL_YEAR,
    SQL_TIMESTAMP,
    CURRENT_ROW_IND,
    EFFECTIVE_DATE,
    EXPIRATION_DATE
FROM DIM_DATE;


--DROP VIEW "V_DIM_LOCATION";
-- Pass-through view for Dim_Location
CREATE SECURE VIEW "V_DIM_LOCATION" AS
SELECT 
    DimLocationID,
    Country,
    StateProvince,
    City,
    PostalCode,
    Address,
    SourceSystem
FROM Dim_Location;


--DROP VIEW "V_DIM_PRODUCT";
-- Pass-through view for Dim_Product
CREATE SECURE VIEW "V_DIM_PRODUCT" AS
SELECT 
    DimProductID,
    ProductID,
    ProductName,
    ProductTypeID,
    ProductType,
    ProductCategoryID,
    ProductCategory,
    Color,
    Style,
    UnitOfMeasureID,
    Weight,
    Price,
    Cost,
    WholesalePrice
FROM Dim_Product;


--DROP VIEW "V_DIM_CUSTOMER";
-- Pass-through view for Dim_Customer
CREATE SECURE VIEW "V_DIM_CUSTOMER" AS
SELECT 
    DimCustomerID,
    CustomerID,
    FirstName,
    LastName,
    FullName,
    Gender,
    EmailAddress,
    DimLocationID
FROM Dim_Customer;

--DROP VIEW "V_DIM_RESELLER";
-- Pass-through view for Dim_Reseller
CREATE SECURE VIEW "V_DIM_RESELLER" AS
SELECT 
    DimResellerID,
    ResellerID,
    ResellerName,
    Contact,
    EmailAddress,
    DimLocationID
FROM Dim_Reseller;

--DROP VIEW "V_DIM_STORE";
-- Pass-through view for Dim_Store
CREATE SECURE VIEW "V_DIM_STORE" AS
SELECT 
    DimStoreID,
    StoreID,
    StoreNumber,
    StoreManager,
    DimLocationID
FROM Dim_Store;


--DROP VIEW "V_DIM_CHANNEL";
-- Pass-through view for Dim_Channel
CREATE SECURE VIEW "V_DIM_CHANNEL" AS
SELECT 
    DimChannelID,
    ChannelID,
    ChannelName,
    ChannelCategoryID,
    ChannelCategory
FROM Dim_Channel;



--DROP VIEW "V_FACT_PRODUCTSALESTARGET";
/*-----Fact Table Pass-Through Views:-----*/
-- Pass-through view for Fact_ProductSalesTarget
CREATE SECURE VIEW "V_FACT_PRODUCTSALESTARGET" AS
SELECT 
    DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
FROM Fact_ProductSalesTarget;


--DROP VIEW "V_FACT_SRCSALESTARGET";
-- Pass-through view for Fact_SRCSalesTarget
CREATE SECURE VIEW "V_FACT_SRCSALESTARGET" AS
SELECT 
    DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
FROM Fact_SRCSalesTarget;


--DROP VIEW "V_FACT_SALESACTUAL";
-- Pass-through view for Fact_SalesActual
CREATE SECURE VIEW "V_FACT_SALESACTUAL" AS
SELECT 
    DimProductID,
    DimStoreID,
    DimResellerID,
    DimCustomerID,
    DimChannelID,
    DimSaleDateID,
    DimLocationID,
    SalesHeaderID,
    SalesDetailID,
    SaleAmount,
    SaleQuantity,
    SaleUnitPrice,
    SaleExtendedCost,
    SaleTotalProfit
FROM Fact_SalesActual;




--2. Data Visualization Support Views (Complex Analytics):


SELECT * FROM "V_STORE_PERFORMANCE_ANALYSIS"
WHERE StoreNumber IN (10, 21)
ORDER BY StoreNumber, YEAR;
--DROP VIEW IF EXISTS "V_STORE_PERFORMANCE_ANALYSIS";
/*View 1: Store Performance Analysis (Simplified) (Questions 1 & 2)*/
-- View 1: Comprehensive Store Performance with Target Comparison = Store performance, target comparison, profitability analysis, and bonus calculations
CREATE OR REPLACE SECURE VIEW "V_STORE_PERFORMANCE_ANALYSIS" AS
SELECT 
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.StateProvince,
    d.YEAR,
    d.QUARTER,
    -- Actual Sales Metrics
    SUM(f.SaleAmount) AS ActualSales,
    SUM(f.SaleQuantity) AS ActualQuantity,
    SUM(f.SaleTotalProfit) AS ActualProfit,
    COUNT(DISTINCT f.SalesHeaderID) AS TransactionCount,
    AVG(f.SaleAmount) AS AvgTransactionValue,
    
    -- Target Sales (from Fact_SRCSalesTarget)
    MAX(t.TargetSales) AS TargetSales,
    
    -- Performance vs Target
    SUM(f.SaleAmount) - MAX(t.TargetSales) AS SalesVariance,
    CASE 
        WHEN MAX(t.TargetSales) = 0 OR MAX(t.TargetSales) IS NULL THEN NULL
        ELSE ((SUM(f.SaleAmount) - MAX(t.TargetSales)) / MAX(t.TargetSales)) * 100
    END AS PerformanceToTargetPercent,
    
    -- Target Achievement Flag
    CASE 
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) THEN 'Met Target'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) * 0.9 THEN 'Near Target (90%+)'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) * 0.75 THEN 'Below Target (75-90%)'
        ELSE 'Significantly Below Target (<75%)'
    END AS TargetAchievementStatus,
    
    -- Profitability Analysis
    CASE 
        WHEN SUM(f.SaleAmount) = 0 THEN 0
        ELSE (SUM(f.SaleTotalProfit) / SUM(f.SaleAmount)) * 100
    END AS ProfitMarginPercent,
    
    -- Bonus Calculation Base (actual vs target for 2013)
    CASE 
        WHEN MAX(t.TargetSales) = 0 OR MAX(t.TargetSales) IS NULL THEN 0
        ELSE SUM(f.SaleAmount) / MAX(t.TargetSales)
    END AS BonusPerformanceRatio,
    
    -- Store Health Indicators
    CASE 
        WHEN SUM(f.SaleTotalProfit) < 0 THEN 'Loss Making'
        WHEN SUM(f.SaleTotalProfit) < 10000 THEN 'Low Profit'
        WHEN SUM(f.SaleTotalProfit) < 50000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS ProfitabilityTier,
    
    -- Monthly Average (for projection purposes)
    SUM(f.SaleAmount) / COUNT(DISTINCT d.MONTH_NUM_IN_YEAR) AS AvgMonthlySales,
    
    -- Store Ranking
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleAmount) DESC) AS StoreRankBySales,
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleTotalProfit) DESC) AS StoreRankByProfit,
    
    -- Year-over-Year Growth (for trend analysis)
    LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR) AS PreviousYearSales,
    CASE 
        WHEN LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR) = 0 THEN NULL
        ELSE ((SUM(f.SaleAmount) - LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR)) / 
              LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR)) * 100
    END AS YoYGrowthPercent

FROM Fact_SalesActual f
JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
LEFT JOIN (
    -- Aggregate targets by store and year
    SELECT 
        DimStoreID,
        YEAR(d2.DATE) AS TargetYear,
        SUM(SalesTargetAmount) AS TargetSales
    FROM Fact_SRCSalesTarget t
    JOIN DIM_DATE d2 ON t.DimTargetDateID = d2.DATE_PKEY
    WHERE DimStoreID != -1
    GROUP BY DimStoreID, YEAR(d2.DATE)
) t ON s.DimStoreID = t.DimStoreID AND d.YEAR = t.TargetYear
WHERE s.StoreID != -1  -- Exclude Unknown stores
GROUP BY s.StoreNumber, s.StoreManager, l.City, l.StateProvince, d.YEAR, d.QUARTER;

--Check View
SELECT * FROM "V_STORE_PERFORMANCE_ANALYSIS";

-------------------------
-------------------------
/*View 2: Day of Week Sales Analysis (Question 3)*/
-- View 2: Day of Week Sales Patterns by Store = Day-of-week sales patterns, product mix by day, weekend vs weekday analysis
CREATE SECURE VIEW "V_DAYOFWEEK_SALES_ANALYSIS" AS
SELECT 
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.StateProvince,
    d.YEAR,
    d.DAY_NAME,
    d.DAY_NUM_IN_WEEK,
    p.ProductCategory,
    p.ProductType,
    -- Sales Metrics by Day of Week
    SUM(f.SaleAmount) AS DailySales,
    SUM(f.SaleQuantity) AS DailyQuantity,
    SUM(f.SaleTotalProfit) AS DailyProfit,
    COUNT(*) AS DailyTransactions,
    AVG(f.SaleAmount) AS AvgTransactionValue,
    -- Day Performance Metrics
    SUM(f.SaleAmount) / COUNT(DISTINCT d.DATE) AS AvgSalesPerDay,
    COUNT(*) / COUNT(DISTINCT d.DATE) AS AvgTransactionsPerDay,
    -- Weekend vs Weekday Analysis
    CASE 
        WHEN d.DAY_NAME IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    -- Peak Performance Indicators
    RANK() OVER (PARTITION BY s.StoreNumber, d.YEAR ORDER BY SUM(f.SaleAmount) DESC) AS DayRankBySales,
    RANK() OVER (PARTITION BY s.StoreNumber, d.YEAR ORDER BY COUNT(*) DESC) AS DayRankByTransactions,
    -- Seasonal Patterns
    d.QUARTER,
    d.MONTH_NAME,
    -- Product Mix Analysis
    SUM(CASE WHEN p.ProductCategory = 'Cosmetics' THEN f.SaleAmount ELSE 0 END) AS CosmeticsSales,
    SUM(CASE WHEN p.ProductCategory = 'Jewelry' THEN f.SaleAmount ELSE 0 END) AS JewelrySales,
    SUM(CASE WHEN p.ProductCategory = 'Baby' THEN f.SaleAmount ELSE 0 END) AS BabySales,
    SUM(CASE WHEN p.ProductCategory = 'Kids Apparel' THEN f.SaleAmount ELSE 0 END) AS KidsApparelSales,
    SUM(CASE WHEN p.ProductCategory = 'Womens Apparel' THEN f.SaleAmount ELSE 0 END) AS WomensApparelSales
FROM Fact_SalesActual f
JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
JOIN Dim_Product p ON f.DimProductID = p.DimProductID
WHERE s.StoreID != -1  -- Exclude Unknown stores
  AND p.ProductID != -1  -- Exclude Unknown products
GROUP BY 
    s.StoreNumber, s.StoreManager, l.City, l.StateProvince,
    d.YEAR, d.DAY_NAME, d.DAY_NUM_IN_WEEK, d.QUARTER, d.MONTH_NAME,
    p.ProductCategory, p.ProductType;

--Check Weekend vs Weekday performance
SELECT StoreNumber, YEAR, DayType, 
       SUM(DailySales) AS TotalSales, 
       AVG(DailySales) AS AvgDailySales,
       SUM(DailyTransactions) AS TotalTransactions
FROM "V_DAYOFWEEK_SALES_ANALYSIS"
WHERE StoreNumber IN (10, 21)
GROUP BY StoreNumber, YEAR, DayType
ORDER BY StoreNumber, YEAR, DayType;

--SELECT * FROM "V_DAYOFWEEK_SALES_ANALYSIS"


/*View 3: Market Expansion Analysis (Question 4)*/
-- View 3: Market Analysis for Store Expansion Opportunities = Market analysis for expansion opportunities, competition assessment, and growth indicators
-- Drop and recreate the fixed view
DROP VIEW IF EXISTS "V_MARKET_EXPANSION_ANALYSIS";

-- Fixed Market Expansion Analysis View
CREATE SECURE VIEW "V_MARKET_EXPANSION_ANALYSIS" AS
SELECT 
    l.Country,
    l.StateProvince,
    l.City,
    d.YEAR,
    -- Market Metrics (FIXED: Handle -1 values properly)
    COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) AS StoresInMarket,
    COUNT(DISTINCT CASE WHEN r.ResellerID != 'Unknown' AND r.ResellerID != '-1' THEN r.ResellerID ELSE NULL END) AS ResellersInMarket,
    COUNT(DISTINCT CASE WHEN c.CustomerID != 'Unknown' AND c.CustomerID != '-1' THEN c.CustomerID ELSE NULL END) AS UniqueCustomers,
    -- Sales Performance
    SUM(f.SaleAmount) AS TotalMarketSales,
    SUM(f.SaleTotalProfit) AS TotalMarketProfit,
    COUNT(*) AS TotalTransactions,
    -- Store Density Analysis (FIXED: Proper NULL handling)
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 THEN 
            SUM(f.SaleAmount)  -- If no stores, show total sales potential
        ELSE 
            SUM(f.SaleAmount) / COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END)
    END AS SalesPerStore,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 THEN 
            SUM(f.SaleTotalProfit)  -- If no stores, show total profit potential
        ELSE 
            SUM(f.SaleTotalProfit) / COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END)
    END AS ProfitPerStore,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 THEN 
            COUNT(*)  -- If no stores, show total transactions
        ELSE 
            COUNT(*) / COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END)
    END AS TransactionsPerStore,
    -- Market Penetration (FIXED)
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 THEN 
            COUNT(DISTINCT CASE WHEN c.CustomerID != 'Unknown' AND c.CustomerID != '-1' THEN c.CustomerID ELSE NULL END)
        ELSE 
            COUNT(DISTINCT CASE WHEN c.CustomerID != 'Unknown' AND c.CustomerID != '-1' THEN c.CustomerID ELSE NULL END) / 
            COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END)
    END AS CustomersPerStore,
    -- Profitability Metrics
    CASE 
        WHEN SUM(f.SaleAmount) = 0 THEN 0
        ELSE (SUM(f.SaleTotalProfit) / SUM(f.SaleAmount)) * 100
    END AS MarketProfitMargin,
    -- Competition Analysis (FIXED)
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN r.ResellerID != 'Unknown' AND r.ResellerID != '-1' THEN r.ResellerID ELSE NULL END) = 0 THEN 'No Competition'
        WHEN COUNT(DISTINCT CASE WHEN r.ResellerID != 'Unknown' AND r.ResellerID != '-1' THEN r.ResellerID ELSE NULL END) <= 2 THEN 'Low Competition'
        WHEN COUNT(DISTINCT CASE WHEN r.ResellerID != 'Unknown' AND r.ResellerID != '-1' THEN r.ResellerID ELSE NULL END) <= 5 THEN 'Moderate Competition'
        ELSE 'High Competition'
    END AS CompetitionLevel,
    -- Market Opportunity Score (FIXED)
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 AND SUM(f.SaleAmount) > 100000 THEN 'Greenfield Opportunity'
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 AND SUM(f.SaleAmount) > 50000 THEN 'Moderate Greenfield'
        WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 THEN 'Small Market'
        WHEN SUM(f.SaleAmount) / COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) > 100000 THEN 'High Opportunity'
        WHEN SUM(f.SaleAmount) / COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) > 50000 THEN 'Moderate Opportunity'
        ELSE 'Low Opportunity'
    END AS ExpansionOpportunity,
    -- Channel Mix Analysis
    SUM(CASE WHEN ch.ChannelCategory = 'Online' THEN f.SaleAmount ELSE 0 END) AS OnlineChannelSales,
    SUM(CASE WHEN ch.ChannelCategory = 'Retail' THEN f.SaleAmount ELSE 0 END) AS RetailChannelSales,
    -- Market Ranking (FIXED: Handle division by zero)
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleAmount) DESC) AS MarketRankBySales,
    RANK() OVER (
        PARTITION BY d.YEAR 
        ORDER BY 
            CASE 
                WHEN COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END) = 0 THEN SUM(f.SaleAmount)
                ELSE SUM(f.SaleAmount) / COUNT(DISTINCT CASE WHEN s.StoreID != -1 THEN s.StoreNumber ELSE NULL END)
            END DESC
    ) AS MarketRankByEfficiency,
    -- Growth Indicators (FIXED: Handle NULLs with -1)
    COALESCE(LAG(SUM(f.SaleAmount)) OVER (PARTITION BY l.Country, l.StateProvince, l.City ORDER BY d.YEAR), -1) AS PriorYearSales,
    CASE 
        WHEN LAG(SUM(f.SaleAmount)) OVER (PARTITION BY l.Country, l.StateProvince, l.City ORDER BY d.YEAR) IS NOT NULL 
        THEN ((SUM(f.SaleAmount) - LAG(SUM(f.SaleAmount)) OVER (PARTITION BY l.Country, l.StateProvince, l.City ORDER BY d.YEAR)) / 
              LAG(SUM(f.SaleAmount)) OVER (PARTITION BY l.Country, l.StateProvince, l.City ORDER BY d.YEAR)) * 100
        ELSE -1
    END AS YearOverYearGrowthPercent
FROM Fact_SalesActual f
JOIN Dim_Location l ON f.DimLocationID = l.DimLocationID
JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
JOIN Dim_Channel ch ON f.DimChannelID = ch.DimChannelID
LEFT JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
LEFT JOIN Dim_Reseller r ON f.DimResellerID = r.DimResellerID
LEFT JOIN Dim_Customer c ON f.DimCustomerID = c.DimCustomerID
WHERE l.DimLocationID != -1  -- Exclude Unknown locations
GROUP BY l.Country, l.StateProvince, l.City, d.YEAR;


--DROP VIEW "V_MARKET_EXPANSION_ANALYSIS";







-- SELECT * FROM "V_STORE_PERFORMANCE_ANALYSIS"
-- Drop and recreate the enhanced Store Performance Analysis View
CREATE OR REPLACE SECURE VIEW "V_STORE_PERFORMANCE_ANALYSIS" AS
-- Quarterly data
SELECT 
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.StateProvince,
    d.YEAR,
    d.QUARTER,
    -- Actual Sales Metrics
    SUM(f.SaleAmount) AS ActualSales,
    SUM(f.SaleQuantity) AS ActualQuantity,
    SUM(f.SaleTotalProfit) AS ActualProfit,
    COUNT(DISTINCT f.SalesHeaderID) AS TransactionCount,
    AVG(f.SaleAmount) AS AvgTransactionValue,
    
    -- Target Sales (from Fact_SRCSalesTarget)
    MAX(t.TargetSales) AS TargetSales,
    
    -- Performance vs Target
    SUM(f.SaleAmount) - MAX(t.TargetSales) AS SalesVariance,
    CASE 
        WHEN MAX(t.TargetSales) = 0 OR MAX(t.TargetSales) IS NULL THEN NULL
        ELSE ((SUM(f.SaleAmount) - MAX(t.TargetSales)) / MAX(t.TargetSales)) * 100
    END AS PerformanceToTargetPercent,
    
    -- Target Achievement Flag
    CASE 
        WHEN MAX(t.TargetSales) IS NULL THEN 'No Target Set'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) THEN 'Met Target'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) * 0.9 THEN 'Near Target (90%+)'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) * 0.75 THEN 'Below Target (75-90%)'
        ELSE 'Significantly Below Target (<75%)'
    END AS TargetAchievementStatus,
    
    -- Profitability Analysis
    CASE 
        WHEN SUM(f.SaleAmount) = 0 THEN 0
        ELSE (SUM(f.SaleTotalProfit) / SUM(f.SaleAmount)) * 100
    END AS ProfitMarginPercent,
    
    -- Bonus Calculation Base (actual vs target for 2013)
    CASE 
        WHEN MAX(t.TargetSales) = 0 OR MAX(t.TargetSales) IS NULL THEN 0
        ELSE SUM(f.SaleAmount) / MAX(t.TargetSales)
    END AS BonusPerformanceRatio,
    
    -- Store Health Indicators
    CASE 
        WHEN SUM(f.SaleTotalProfit) < 0 THEN 'Loss Making'
        WHEN SUM(f.SaleTotalProfit) < 10000 THEN 'Low Profit'
        WHEN SUM(f.SaleTotalProfit) < 50000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS ProfitabilityTier,
    
    -- Monthly Average (for projection purposes)
    SUM(f.SaleAmount) / COUNT(DISTINCT d.MONTH_NUM_IN_YEAR) AS AvgMonthlySales,
    
    -- Store Ranking
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleAmount) DESC) AS StoreRankBySales,
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleTotalProfit) DESC) AS StoreRankByProfit,
    
    -- Year-over-Year Growth (for trend analysis)
    LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR) AS PreviousYearSales,
    CASE 
        WHEN LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR) = 0 THEN NULL
        ELSE ((SUM(f.SaleAmount) - LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR)) / 
              LAG(SUM(f.SaleAmount)) OVER (PARTITION BY s.StoreNumber ORDER BY d.YEAR)) * 100
    END AS YoYGrowthPercent
FROM Fact_SalesActual f
JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
LEFT JOIN (
    -- Aggregate targets by store and year
    SELECT 
        DimStoreID,
        YEAR(d2.DATE) AS TargetYear,
        SUM(SalesTargetAmount) AS TargetSales
    FROM Fact_SRCSalesTarget t
    JOIN DIM_DATE d2 ON t.DimTargetDateID = d2.DATE_PKEY
    WHERE DimStoreID != -1
    GROUP BY DimStoreID, YEAR(d2.DATE)
) t ON s.DimStoreID = t.DimStoreID AND d.YEAR = t.TargetYear
WHERE s.StoreID != -1  -- Exclude Unknown stores
GROUP BY s.StoreNumber, s.StoreManager, l.City, l.StateProvince, d.YEAR, d.QUARTER

UNION ALL

-- Annual summary rows (QUARTER = 0)
SELECT 
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.StateProvince,
    d.YEAR,
    0 AS QUARTER,  -- 0 indicates annual total
    -- Actual Sales Metrics (Annual)
    SUM(f.SaleAmount) AS ActualSales,
    SUM(f.SaleQuantity) AS ActualQuantity,
    SUM(f.SaleTotalProfit) AS ActualProfit,
    COUNT(DISTINCT f.SalesHeaderID) AS TransactionCount,
    AVG(f.SaleAmount) AS AvgTransactionValue,
    
    -- Target Sales (Annual)
    MAX(t.TargetSales) AS TargetSales,
    
    -- Performance vs Target (Annual)
    SUM(f.SaleAmount) - MAX(t.TargetSales) AS SalesVariance,
    CASE 
        WHEN MAX(t.TargetSales) = 0 OR MAX(t.TargetSales) IS NULL THEN NULL
        ELSE ((SUM(f.SaleAmount) - MAX(t.TargetSales)) / MAX(t.TargetSales)) * 100
    END AS PerformanceToTargetPercent,
    
    -- Target Achievement Flag (Annual)
    CASE 
        WHEN MAX(t.TargetSales) IS NULL THEN 'No Target Set'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) THEN 'Met Annual Target'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) * 0.9 THEN 'Near Annual Target (90%+)'
        WHEN SUM(f.SaleAmount) >= MAX(t.TargetSales) * 0.75 THEN 'Below Annual Target (75-90%)'
        ELSE 'Significantly Below Annual Target (<75%)'
    END AS TargetAchievementStatus,
    
    -- Profitability Analysis (Annual)
    CASE 
        WHEN SUM(f.SaleAmount) = 0 THEN 0
        ELSE (SUM(f.SaleTotalProfit) / SUM(f.SaleAmount)) * 100
    END AS ProfitMarginPercent,
    
    -- Bonus Calculation Base (actual vs target for 2013) - Annual is what matters
    CASE 
        WHEN d.YEAR = 2013 AND MAX(t.TargetSales) > 0 THEN 
            SUM(f.SaleAmount) / MAX(t.TargetSales)
        ELSE NULL
    END AS BonusPerformanceRatio,
    
    -- Store Health Indicators (Annual)
    CASE 
        WHEN SUM(f.SaleTotalProfit) < 0 THEN 'Loss Making'
        WHEN SUM(f.SaleTotalProfit) < 50000 THEN 'Low Profit'
        WHEN SUM(f.SaleTotalProfit) < 200000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS ProfitabilityTier,
    
    -- Monthly Average (Annual)
    SUM(f.SaleAmount) / 12 AS AvgMonthlySales,
    
    -- Store Ranking (Annual)
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleAmount) DESC) AS StoreRankBySales,
    RANK() OVER (PARTITION BY d.YEAR ORDER BY SUM(f.SaleTotalProfit) DESC) AS StoreRankByProfit,
    
    -- Year-over-Year Growth (Annual comparison)
    NULL AS PreviousYearSales,  -- Will be calculated in outer query
    NULL AS YoYGrowthPercent    -- Will be calculated in outer query
    
FROM Fact_SalesActual f
JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
LEFT JOIN (
    -- Aggregate targets by store and year
    SELECT 
        DimStoreID,
        YEAR(d2.DATE) AS TargetYear,
        SUM(SalesTargetAmount) AS TargetSales
    FROM Fact_SRCSalesTarget t
    JOIN DIM_DATE d2 ON t.DimTargetDateID = d2.DATE_PKEY
    WHERE DimStoreID != -1
    GROUP BY DimStoreID, YEAR(d2.DATE)
) t ON s.DimStoreID = t.DimStoreID AND d.YEAR = t.TargetYear
WHERE s.StoreID != -1  -- Exclude Unknown stores
GROUP BY s.StoreNumber, s.StoreManager, l.City, l.StateProvince, d.YEAR

ORDER BY StoreNumber, YEAR, QUARTER;

-- Test queries for the specific business questions

-- Question 1: Stores 10 and 21 performance
SELECT 
    'Stores 10 & 21 Analysis' AS Analysis,
    StoreNumber,
    YEAR,
    ActualSales,
    TargetSales,
    SalesVariancePercent,
    TargetAchievementStatus,
    ProfitMarginPercent,
    YearOverYearGrowthPercent,
    ClosureRisk,
    Projected2014Sales
FROM "V_STORE_PERFORMANCE_ANALYSIS"
WHERE StoreNumber IN (10, 21)
ORDER BY StoreNumber, YEAR;

-----
SELECT * FROM "V_STORE_PERFORMANCE_ANALYSIS"
WHERE StoreNumber IN (10, 21)
ORDER BY StoreNumber, YEAR;
-----

-- Question 2: 2013 Bonus Distribution ($2M pool)
WITH BonusCalculation AS (
    SELECT 
        StoreNumber,
        StoreName,
        ActualSales,
        TargetSales,
        SalesVariancePercent,
        BonusEligibility,
        CASE 
            WHEN BonusEligibility = 'High Bonus' THEN 3
            WHEN BonusEligibility = 'Standard Bonus' THEN 2
            WHEN BonusEligibility = 'Low Bonus' THEN 1
            ELSE 0
        END AS BonusWeight
    FROM "V_STORE_PERFORMANCE_ANALYSIS"
    WHERE YEAR = 2013 AND StoreNumber IS NOT NULL
)
SELECT 
    '2013 Bonus Distribution' AS Analysis,
    StoreNumber,
    StoreName,
    ActualSales,
    TargetSales,
    SalesVariancePercent,
    BonusEligibility,
    BonusWeight,
    CASE 
        WHEN SUM(BonusWeight) OVER() > 0 THEN
            ROUND((BonusWeight * 2000000.0) / SUM(BonusWeight) OVER(), 0)
        ELSE 0
    END AS RecommendedBonus
FROM BonusCalculation
ORDER BY RecommendedBonus DESC;




------------------------
------------------------ SELECT * FROM "V_PRODUCT_SALES_BY_DOW" 
-- View: Product Sales by Day of Week Analysis for Stores 10 and 21 -- Answers Q3
-- Revised View: Product Sales by Day of Week Analysis for Stores 10 and 21
-- Enhanced with date measures for better Tableau visualization
CREATE OR REPLACE SECURE VIEW "V_PRODUCT_SALES_BY_DOW" AS
WITH 
-- Base sales data with corrected day of week information
SalesByDOW AS (
    SELECT 
        s.StoreNumber,
        s.StoreManager,
        l.City,
        l.StateProvince,
        p.DimProductID,
        p.ProductName,
        p.ProductCategory,
        p.ProductType,
        d.DATE AS SaleDate,  -- Add actual date for Tableau
        d.YEAR,
        d.QUARTER,
        d.MONTH_NUM_IN_YEAR,
        d.MONTH_NAME,
        d.WEEK_NUM_IN_YEAR,
        d.DAY_NUM_IN_WEEK,
        d.DAY_NAME,
        -- Fix the WEEKDAY_IND logic
        CASE 
            WHEN d.DAY_NAME IN ('Saturday', 'Sunday') THEN 'Weekend'
            ELSE 'Weekday'
        END AS WEEKDAY_IND,
        f.SaleAmount,
        f.SaleQuantity,
        f.SaleTotalProfit,
        f.SalesHeaderID,
        f.DimCustomerID
    FROM Fact_SalesActual f
    JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
    JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
    JOIN Dim_Product p ON f.DimProductID = p.DimProductID
    JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
    WHERE s.StoreNumber IN (10, 21)  -- Focus on stores 10 and 21
      AND s.StoreID != -1
),
-- Aggregate by store, date dimensions, day of week, and product category
DetailedSales AS (
    SELECT 
        StoreNumber,
        StoreManager,
        City,
        StateProvince,
        YEAR,
        QUARTER,
        COALESCE(MONTH_NUM_IN_YEAR, -1) AS MONTH_NUM_IN_YEAR,
        COALESCE(MONTH_NAME, 'Unknown') AS MONTH_NAME,
        COALESCE(WEEK_NUM_IN_YEAR, -1) AS WEEK_NUM_IN_YEAR,
        DAY_NUM_IN_WEEK,
        DAY_NAME,
        WEEKDAY_IND,
        ProductCategory,
        ProductType,
        
        -- Date measures for Tableau
        COALESCE(MIN(SaleDate), DATE('1900-01-01')) AS FirstSaleDate,  -- First date in the period
        COALESCE(MAX(SaleDate), DATE('1900-01-01')) AS LastSaleDate,   -- Last date in the period
        COALESCE(COUNT(DISTINCT SaleDate), 0) AS DaysWithSales,  -- Number of days with sales
        
        -- Construct a representative date for weekly patterns (using first Monday of 2013 as base)
        -- This helps Tableau show day patterns without actual dates
        DATE('2013-01-07') + (DAY_NUM_IN_WEEK - 2) AS WeekPatternDate,
        
        -- Sales Metrics
        COALESCE(COUNT(DISTINCT SalesHeaderID), 0) AS TransactionCount,
        COALESCE(COUNT(DISTINCT DimCustomerID), 0) AS UniqueCustomers,
        COALESCE(SUM(SaleAmount), 0) AS TotalSales,
        COALESCE(SUM(SaleQuantity), 0) AS TotalQuantity,
        COALESCE(SUM(SaleTotalProfit), 0) AS TotalProfit,
        
        -- Average Metrics
        COALESCE(AVG(SaleAmount), 0) AS AvgTransactionValue,
        CASE 
            WHEN COUNT(DISTINCT SalesHeaderID) = 0 THEN 0
            ELSE COALESCE(SUM(SaleAmount) / COUNT(DISTINCT SalesHeaderID), 0)
        END AS AvgSalePerTransaction,
        
        CASE 
            WHEN SUM(SaleQuantity) = 0 THEN 0
            ELSE COALESCE(SUM(SaleAmount) / SUM(SaleQuantity), 0)
        END AS AvgPricePerUnit,
        
        -- Profitability
        CASE 
            WHEN SUM(SaleAmount) = 0 THEN 0
            ELSE COALESCE((SUM(SaleTotalProfit) / SUM(SaleAmount)) * 100, 0)
        END AS ProfitMarginPercent,
        
        -- Daily averages (for the specific day of week)
        COALESCE(SUM(SaleAmount) / NULLIF(COUNT(DISTINCT SaleDate), 0), 0) AS AvgDailySalesForDOW
        
    FROM SalesByDOW
    GROUP BY 
        StoreNumber, StoreManager, City, StateProvince,
        YEAR, QUARTER, MONTH_NUM_IN_YEAR, MONTH_NAME, WEEK_NUM_IN_YEAR,
        DAY_NUM_IN_WEEK, DAY_NAME, WEEKDAY_IND,
        ProductCategory, ProductType
),
-- Add rankings and classifications
RankedSales AS (
    SELECT 
        *,
        -- Day of Week Rankings (within each store, year, and category)
        RANK() OVER (
            PARTITION BY StoreNumber, YEAR, ProductCategory 
            ORDER BY TotalSales DESC
        ) AS DOW_SalesRank_ByCategory,
        
        -- Percentage of Weekly Sales (within quarter and category)
        CASE 
            WHEN SUM(TotalSales) OVER (PARTITION BY StoreNumber, YEAR, QUARTER, ProductCategory) = 0 THEN 0
            ELSE TotalSales / SUM(TotalSales) OVER (PARTITION BY StoreNumber, YEAR, QUARTER, ProductCategory) * 100
        END AS PercentOfWeeklySales,
        
        -- Day Classification (within quarter, across all categories)
        CASE 
            WHEN RANK() OVER (
                PARTITION BY StoreNumber, YEAR, QUARTER 
                ORDER BY TotalSales DESC
            ) = 1 THEN 'Peak Day'
            WHEN RANK() OVER (
                PARTITION BY StoreNumber, YEAR, QUARTER 
                ORDER BY TotalSales DESC
            ) <= 3 THEN 'High Traffic'
            ELSE 'Regular'
        END AS DayClassification,
        
        -- Period identifier for Tableau
        CAST(YEAR AS VARCHAR) || '-Q' || CAST(QUARTER AS VARCHAR) AS YearQuarter,
        CAST(YEAR AS VARCHAR) || '-' || LPAD(CAST(MONTH_NUM_IN_YEAR AS VARCHAR), 2, '0') AS YearMonth
    
    FROM DetailedSales
)
-- Main query
SELECT * FROM RankedSales

UNION ALL

-- Annual summary rows by day of week (all products combined)
-- Note: Window functions are simplified to avoid syntax errors
SELECT 
    StoreNumber,
    StoreManager,
    City,
    StateProvince,
    YEAR,
    0 AS QUARTER,  -- 0 indicates annual summary
    -1 AS MONTH_NUM_IN_YEAR,  -- Use -1 for NULL
    'All Months' AS MONTH_NAME,
    -1 AS WEEK_NUM_IN_YEAR,  -- Use -1 for NULL
    DAY_NUM_IN_WEEK,
    DAY_NAME,
    CASE 
        WHEN DAY_NAME IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS WEEKDAY_IND,
    'All Categories' AS ProductCategory,
    'All Types' AS ProductType,
    
    -- Date measures for annual summary
    MIN(SaleDate) AS FirstSaleDate,
    MAX(SaleDate) AS LastSaleDate,
    COUNT(DISTINCT SaleDate) AS DaysWithSales,
    DATE('2013-01-07') + (DAY_NUM_IN_WEEK - 2) AS WeekPatternDate,
    
    -- Annual Sales Metrics by DOW
    COALESCE(COUNT(DISTINCT SalesHeaderID), 0) AS TransactionCount,
    COALESCE(COUNT(DISTINCT DimCustomerID), 0) AS UniqueCustomers,
    COALESCE(SUM(SaleAmount), 0) AS TotalSales,
    COALESCE(SUM(SaleQuantity), 0) AS TotalQuantity,
    COALESCE(SUM(SaleTotalProfit), 0) AS TotalProfit,
    
    -- Average Metrics
    COALESCE(AVG(SaleAmount), 0) AS AvgTransactionValue,
    CASE 
        WHEN COUNT(DISTINCT SalesHeaderID) = 0 THEN 0
        ELSE COALESCE(SUM(SaleAmount) / COUNT(DISTINCT SalesHeaderID), 0)
    END AS AvgSalePerTransaction,
    
    CASE 
        WHEN SUM(SaleQuantity) = 0 THEN 0
        ELSE COALESCE(SUM(SaleAmount) / SUM(SaleQuantity), 0)
    END AS AvgPricePerUnit,
    
    -- Profitability
    CASE 
        WHEN SUM(SaleAmount) = 0 THEN 0
        ELSE COALESCE((SUM(SaleTotalProfit) / SUM(SaleAmount)) * 100, 0)
    END AS ProfitMarginPercent,
    
    -- Daily average for this DOW across the year
    COALESCE(SUM(SaleAmount) / NULLIF(COUNT(DISTINCT SaleDate), 0), 0) AS AvgDailySalesForDOW,
    
    -- Simplified rankings (will be recalculated in Tableau if needed)
    0 AS DOW_SalesRank_ByCategory,
    0.0 AS PercentOfWeeklySales,
    'To Be Calculated' AS DayClassification,
    
    -- Period identifiers
    CAST(YEAR AS VARCHAR) || '-Annual' AS YearQuarter,
    CAST(YEAR AS VARCHAR) || '-All' AS YearMonth

FROM SalesByDOW
GROUP BY 
    StoreNumber, StoreManager, City, StateProvince,
    YEAR, DAY_NUM_IN_WEEK, DAY_NAME

ORDER BY 
    StoreNumber, YEAR, QUARTER, DAY_NUM_IN_WEEK, ProductCategory;



-------------------
-------------------
------------------- SELECT * FROM "V_DOW_SALES_INSIGHTS_10_21"
-- Executive Summary View: Day of Week Insights for Stores 10 and 21
-- Provides actionable insights about sales patterns and trends

CREATE OR REPLACE SECURE VIEW "V_DOW_SALES_INSIGHTS_10_21" AS
WITH 
-- Get daily averages and patterns
DailyPatterns AS (
    SELECT 
        s.StoreNumber,
        s.StoreManager,
        d.YEAR,
        d.DAY_NUM_IN_WEEK,
        d.DAY_NAME,
        CASE 
            WHEN d.DAY_NAME IN ('Saturday', 'Sunday') THEN 'Weekend'
            ELSE 'Weekday'
        END AS WEEKDAY_IND,
        COUNT(DISTINCT d.DATE) AS DaysCount,  -- Number of this weekday in period
        COUNT(DISTINCT f.SalesHeaderID) AS TotalTransactions,
        COUNT(DISTINCT f.DimCustomerID) AS TotalCustomers,
        SUM(f.SaleAmount) AS TotalSales,
        SUM(f.SaleQuantity) AS TotalUnits,
        SUM(f.SaleTotalProfit) AS TotalProfit
    FROM Fact_SalesActual f
    JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
    JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
    WHERE s.StoreNumber IN (10, 21)
      AND s.StoreID != -1
    GROUP BY s.StoreNumber, s.StoreManager, d.YEAR, d.DAY_NUM_IN_WEEK, d.DAY_NAME
),
-- Calculate performance metrics
PerformanceMetrics AS (
    SELECT 
        *,
        -- Daily averages
        TotalSales / NULLIF(DaysCount, 0) AS AvgDailySales,
        TotalTransactions / NULLIF(DaysCount, 0) AS AvgDailyTransactions,
        TotalCustomers / NULLIF(DaysCount, 0) AS AvgDailyCustomers,
        TotalUnits / NULLIF(DaysCount, 0) AS AvgDailyUnits,
        
        -- Performance index (100 = average for that store/year)
        (TotalSales / NULLIF(DaysCount, 0)) / 
        NULLIF(AVG(TotalSales / NULLIF(DaysCount, 0)) OVER (PARTITION BY StoreNumber, YEAR), 0) * 100 AS SalesIndex,
        
        -- Profit margin
        CASE 
            WHEN TotalSales = 0 THEN 0
            ELSE (TotalProfit / TotalSales) * 100
        END AS ProfitMarginPercent,
        
        -- Average basket metrics
        CASE 
            WHEN TotalTransactions = 0 THEN 0
            ELSE TotalSales / TotalTransactions
        END AS AvgBasketSize,
        
        CASE 
            WHEN TotalTransactions = 0 THEN 0
            ELSE TotalUnits::FLOAT / TotalTransactions
        END AS AvgItemsPerTransaction
        
    FROM DailyPatterns
)
SELECT 
    StoreNumber,
    StoreManager,
    YEAR,
    DAY_NUM_IN_WEEK,
    DAY_NAME,
    WEEKDAY_IND,
    
    -- Core Metrics
    AvgDailySales,
    AvgDailyTransactions,
    AvgDailyCustomers,
    AvgDailyUnits,
    AvgBasketSize,
    AvgItemsPerTransaction,
    ProfitMarginPercent,
    
    -- Performance Indicators
    SalesIndex,
    RANK() OVER (PARTITION BY StoreNumber, YEAR ORDER BY AvgDailySales DESC) AS DayRank,
    
    -- Performance Category
    CASE 
        WHEN SalesIndex >= 115 THEN 'Star Day'
        WHEN SalesIndex >= 105 THEN 'Above Average'
        WHEN SalesIndex >= 95 THEN 'Average'
        WHEN SalesIndex >= 85 THEN 'Below Average'
        ELSE 'Underperforming'
    END AS PerformanceCategory,
    
    -- Insights and Recommendations
    CASE 
        -- Weekend insights
        WHEN WEEKDAY_IND = 'Weekend' AND SalesIndex >= 115 THEN 'Weekend Winner - Maintain momentum'
        WHEN WEEKDAY_IND = 'Weekend' AND SalesIndex < 100 THEN 'Weekend Opportunity - Consider promotions'
        
        -- Weekday insights
        WHEN WEEKDAY_IND = 'Weekday' AND DAY_NAME = 'Friday' AND SalesIndex >= 110 THEN 'Strong Friday - Pre-weekend shopping'
        WHEN WEEKDAY_IND = 'Weekday' AND DAY_NAME = 'Monday' AND SalesIndex < 90 THEN 'Slow Monday - Target with deals'
        
        -- General patterns
        WHEN SalesIndex >= 120 THEN 'Peak Performance - Ensure adequate staffing'
        WHEN SalesIndex < 85 AND AvgDailyCustomers > 0 THEN 'Low Conversion - Review merchandising'
        WHEN AvgBasketSize < (SELECT AVG(p3.AvgBasketSize) FROM PerformanceMetrics p3 WHERE p3.StoreNumber = PerformanceMetrics.StoreNumber) * 0.9 
            THEN 'Small Baskets - Push add-on sales'
        
        ELSE 'Stable Performance'
    END AS ActionableInsight,
    
    -- Compare stores
    AvgDailySales - 
    (SELECT AVG(p2.AvgDailySales) 
     FROM PerformanceMetrics p2 
     WHERE p2.StoreNumber != PerformanceMetrics.StoreNumber 
       AND p2.YEAR = PerformanceMetrics.YEAR 
       AND p2.DAY_NUM_IN_WEEK = PerformanceMetrics.DAY_NUM_IN_WEEK) AS SalesDiffVsOtherStore,
    
    -- Staffing recommendation
    CASE 
        WHEN AvgDailyTransactions > (SELECT AVG(p4.AvgDailyTransactions) * 1.15 FROM PerformanceMetrics p4
                                     WHERE p4.StoreNumber = PerformanceMetrics.StoreNumber 
                                     AND p4.YEAR = PerformanceMetrics.YEAR) THEN 'Increase Staff'
        WHEN AvgDailyTransactions < (SELECT AVG(p5.AvgDailyTransactions) * 0.85 FROM PerformanceMetrics p5
                                     WHERE p5.StoreNumber = PerformanceMetrics.StoreNumber 
                                     AND p5.YEAR = PerformanceMetrics.YEAR) THEN 'Reduce Staff'
        ELSE 'Normal Staffing'
    END AS StaffingRecommendation

FROM PerformanceMetrics

UNION ALL

-- Summary comparison row
SELECT 
    pm.StoreNumber,
    pm.StoreManager,
    pm.YEAR,
    0 AS DAY_NUM_IN_WEEK,
    'WEEK SUMMARY' AS DAY_NAME,
    'Summary' AS WEEKDAY_IND,
    
    AVG(pm.AvgDailySales) AS AvgDailySales,
    AVG(pm.AvgDailyTransactions) AS AvgDailyTransactions,
    AVG(pm.AvgDailyCustomers) AS AvgDailyCustomers,
    AVG(pm.AvgDailyUnits) AS AvgDailyUnits,
    AVG(pm.AvgBasketSize) AS AvgBasketSize,
    AVG(pm.AvgItemsPerTransaction) AS AvgItemsPerTransaction,
    AVG(pm.ProfitMarginPercent) AS ProfitMarginPercent,
    
    100 AS SalesIndex,  -- Average by definition
    NULL AS DayRank,
    
    CASE 
        WHEN COUNT(CASE WHEN pm.SalesIndex >= 115 THEN 1 END) >= 3 THEN 'High Performing Store'
        WHEN COUNT(CASE WHEN pm.SalesIndex < 95 THEN 1 END) >= 4 THEN 'Needs Attention'
        ELSE 'Balanced Performance'
    END AS PerformanceCategory,
    
    CASE 
        WHEN MAX(pm.SalesIndex) - MIN(pm.SalesIndex) > 40 THEN 'High Daily Variance - Review scheduling'
        WHEN MAX(pm.SalesIndex) - MIN(pm.SalesIndex) < 20 THEN 'Consistent Daily Performance'
        WHEN AVG(CASE WHEN pm.WEEKDAY_IND = 'Weekend' THEN pm.SalesIndex END) > 
             AVG(CASE WHEN pm.WEEKDAY_IND = 'Weekday' THEN pm.SalesIndex END) * 1.2 THEN 'Weekend-Heavy Store'
        WHEN AVG(CASE WHEN pm.WEEKDAY_IND = 'Weekday' THEN pm.SalesIndex END) > 
             AVG(CASE WHEN pm.WEEKDAY_IND = 'Weekend' THEN pm.SalesIndex END) * 1.1 THEN 'Weekday-Heavy Store'
        ELSE 'Balanced Week Pattern'
    END AS ActionableInsight,
    
    0 AS SalesDiffVsOtherStore,
    'Review Weekly Pattern' AS StaffingRecommendation

FROM PerformanceMetrics pm
GROUP BY pm.StoreNumber, pm.StoreManager, pm.YEAR

ORDER BY StoreNumber, YEAR, DAY_NUM_IN_WEEK;





----------Shanivi
----------SELECT * FROM "SV_TARGET_ACTUAL_COMPARISON"
CREATE SECURE VIEW "SV_TARGET_ACTUAL_COMPARISON" AS
SELECT 
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.StateProvince,
    d.YEAR,
    -- Actual Performance
    SUM(f.SaleAmount) AS ActualSales,
    SUM(f.SaleTotalProfit) AS ActualProfit,
    -- Target Performance (separate query for targets)
    COALESCE(target_data.SalesTarget, 0) AS SalesTarget,
    -- Performance Metrics
    SUM(f.SaleAmount) - COALESCE(target_data.SalesTarget, 0) AS SalesVariance,
    CASE 
        WHEN COALESCE(target_data.SalesTarget, 0) = 0 THEN 0
        ELSE (SUM(f.SaleAmount) / target_data.SalesTarget) * 100
    END AS TargetAchievementPercent,
    CASE 
        WHEN COALESCE(target_data.SalesTarget, 0) = 0 THEN 'No Target Set'
        WHEN SUM(f.SaleAmount) >= target_data.SalesTarget * 1.1 THEN 'Exceeds Target (110%+)'
        WHEN SUM(f.SaleAmount) >= target_data.SalesTarget THEN 'Meets Target (100-110%)'
        WHEN SUM(f.SaleAmount) >= target_data.SalesTarget * 0.9 THEN 'Near Target (90-100%)'
        WHEN SUM(f.SaleAmount) >= target_data.SalesTarget * 0.75 THEN 'Below Target (75-90%)'
        ELSE 'Poor Performance (<75%)'
    END AS PerformanceRating,
    -- Bonus Calculation
    CASE 
        WHEN COALESCE(target_data.SalesTarget, 0) = 0 THEN 0
        ELSE SUM(f.SaleAmount) / target_data.SalesTarget
    END AS BonusMultiplier,
    -- Store Viability Assessment
    CASE 
        WHEN SUM(f.SaleTotalProfit) < 0 THEN 'Consider Closure - Loss Making'
        WHEN SUM(f.SaleTotalProfit) < 5000 THEN 'At Risk - Very Low Profit'
        WHEN SUM(f.SaleTotalProfit) < 25000 AND SUM(f.SaleAmount) < COALESCE(target_data.SalesTarget, 0) * 0.8 THEN 'Under Review - Low Performance'
        ELSE 'Viable Store'
    END AS StoreViabilityStatus
FROM Fact_SalesActual f
JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
LEFT JOIN (
    SELECT 
        st.DimStoreID,
        dt.YEAR,
        SUM(st.SalesTargetAmount) AS SalesTarget
    FROM Fact_SRCSalesTarget st
    JOIN DIM_DATE dt ON st.DimTargetDateID = dt.DATE_PKEY
    GROUP BY st.DimStoreID, dt.YEAR
) target_data ON s.DimStoreID = target_data.DimStoreID AND d.YEAR = target_data.YEAR
WHERE s.StoreID != -1
GROUP BY s.StoreNumber, s.StoreManager, l.City, l.StateProvince, d.YEAR, target_data.SalesTarget;


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- =====================================================
-- Store Expansion Analysis View
-- Purpose: Analyze market opportunities for new store openings
-- Business Question: Should new stores be opened? Where?
-- =====================================================
-- SELECT * FROM VW_Store_Expansion_Analysis

CREATE OR REPLACE VIEW VW_Store_Expansion_Analysis AS

WITH location_sales AS (
    -- Get all sales with proper location hierarchy
    SELECT 
        -- Location Information
        COALESCE(
            CASE WHEN fsa.DimStoreID != -1 THEN sl.Country ELSE NULL END,
            CASE WHEN fsa.DimResellerID != -1 THEN rl.Country ELSE NULL END,
            CASE WHEN fsa.DimCustomerID != -1 THEN cl.Country ELSE NULL END,
            fl.Country,
            'Unknown'
        ) AS Country,
        
        COALESCE(
            CASE WHEN fsa.DimStoreID != -1 THEN sl.StateProvince ELSE NULL END,
            CASE WHEN fsa.DimResellerID != -1 THEN rl.StateProvince ELSE NULL END,
            CASE WHEN fsa.DimCustomerID != -1 THEN cl.StateProvince ELSE NULL END,
            fl.StateProvince,
            'Unknown'
        ) AS StateProvince,
        
        COALESCE(
            CASE WHEN fsa.DimStoreID != -1 THEN sl.City ELSE NULL END,
            CASE WHEN fsa.DimResellerID != -1 THEN rl.City ELSE NULL END,
            CASE WHEN fsa.DimCustomerID != -1 THEN cl.City ELSE NULL END,
            fl.City,
            'Unknown'
        ) AS City,
        
        -- Sales Channel Information
        CASE 
            WHEN fsa.DimStoreID != -1 THEN 'Store'
            WHEN fsa.DimResellerID != -1 THEN 'Reseller'
            WHEN fsa.DimCustomerID != -1 THEN 'Online'
            ELSE 'Unknown'
        END AS SalesChannel,
        
        -- Store Information (if applicable)
        CASE WHEN fsa.DimStoreID != -1 THEN ds.StoreNumber ELSE NULL END AS StoreNumber,
        CASE WHEN fsa.DimStoreID != -1 THEN ds.StoreManager ELSE NULL END AS StoreManager,
        
        -- Reseller Information (if applicable)
        CASE WHEN fsa.DimResellerID != -1 THEN dr.ResellerName ELSE NULL END AS ResellerName,
        
        -- Date Information
        dd.YEAR,
        dd.QUARTER,
        dd.MONTH_NAME,
        
        -- Sales Metrics
        fsa.SaleAmount,
        fsa.SaleQuantity,
        fsa.SaleTotalProfit,
        
        -- Product Information
        dp.ProductName,
        dp.ProductCategory,
        dp.ProductType
        
    FROM Fact_SalesActual fsa
    
    -- Date Dimension
    LEFT JOIN DIM_DATE dd ON fsa.DimSaleDateID = dd.DATE_PKEY
    
    -- Store Dimension and Location
    LEFT JOIN Dim_Store ds ON fsa.DimStoreID = ds.DimStoreID
    LEFT JOIN Dim_Location sl ON ds.DimLocationID = sl.DimLocationID
    
    -- Reseller Dimension and Location
    LEFT JOIN Dim_Reseller dr ON fsa.DimResellerID = dr.DimResellerID
    LEFT JOIN Dim_Location rl ON dr.DimLocationID = rl.DimLocationID
    
    -- Customer Dimension and Location
    LEFT JOIN Dim_Customer dc ON fsa.DimCustomerID = dc.DimCustomerID
    LEFT JOIN Dim_Location cl ON dc.DimLocationID = cl.DimLocationID
    
    -- Fact Table Location (fallback)
    LEFT JOIN Dim_Location fl ON fsa.DimLocationID = fl.DimLocationID
    
    -- Product Dimension
    LEFT JOIN Dim_Product dp ON fsa.DimProductID = dp.DimProductID
),

city_metrics AS (
    -- Aggregate metrics by city and channel
    SELECT 
        Country,
        StateProvince,
        City,
        SalesChannel,
        YEAR,
        
        -- Sales Performance Metrics
        COUNT(*) AS TransactionCount,
        ROUND(SUM(SaleAmount), 2) AS TotalSales,
        ROUND(SUM(SaleTotalProfit), 2) AS TotalProfit,
        ROUND(SUM(SaleQuantity), 0) AS TotalQuantity,
        ROUND(AVG(SaleAmount), 2) AS AvgTransactionValue,
        ROUND(SUM(SaleTotalProfit) / NULLIF(SUM(SaleAmount), 0) * 100, 2) AS ProfitMarginPct,
        
        -- Store/Reseller Count
        COUNT(DISTINCT StoreNumber) AS StoreCount,
        COUNT(DISTINCT ResellerName) AS ResellerCount
        
    FROM location_sales
    WHERE Country != 'Unknown' 
      AND StateProvince != 'Unknown' 
      AND City != 'Unknown'
    GROUP BY Country, StateProvince, City, SalesChannel, YEAR
),

city_totals AS (
    -- City-level totals across all channels and years
    SELECT 
        Country,
        StateProvince,
        City,
        
        -- Overall Performance
        SUM(TotalSales) AS CityTotalSales,
        SUM(TotalProfit) AS CityTotalProfit,
        SUM(TotalQuantity) AS CityTotalQuantity,
        SUM(TransactionCount) AS CityTotalTransactions,
        ROUND(AVG(AvgTransactionValue), 2) AS CityAvgTransactionValue,
        ROUND(SUM(TotalProfit) / NULLIF(SUM(TotalSales), 0) * 100, 2) AS CityProfitMarginPct,
        
        -- Channel Mix
        SUM(CASE WHEN SalesChannel = 'Store' THEN TotalSales ELSE 0 END) AS StoreSales,
        SUM(CASE WHEN SalesChannel = 'Online' THEN TotalSales ELSE 0 END) AS OnlineSales,
        SUM(CASE WHEN SalesChannel = 'Reseller' THEN TotalSales ELSE 0 END) AS ResellerSales,
        
        -- Competition Analysis
        MAX(CASE WHEN SalesChannel = 'Store' THEN StoreCount ELSE 0 END) AS ExistingStores,
        MAX(CASE WHEN SalesChannel = 'Reseller' THEN ResellerCount ELSE 0 END) AS CompetingResellers,
        
        -- Market Validation Indicators
        CASE WHEN SUM(CASE WHEN SalesChannel = 'Store' THEN TotalSales ELSE 0 END) > 0 THEN 1 ELSE 0 END AS HasStorePresence,
        CASE WHEN SUM(CASE WHEN SalesChannel = 'Online' THEN TotalSales ELSE 0 END) > 0 THEN 1 ELSE 0 END AS HasOnlineDemand,
        CASE WHEN SUM(CASE WHEN SalesChannel = 'Reseller' THEN TotalSales ELSE 0 END) > 0 THEN 1 ELSE 0 END AS HasResellerPresence
        
    FROM city_metrics
    GROUP BY Country, StateProvince, City
),

market_analysis AS (
    -- Calculate market opportunity scores
    SELECT 
        *,
        
        -- Market Size Score (1-5 scale based on total sales)
        CASE 
            WHEN CityTotalSales >= 500000 THEN 5
            WHEN CityTotalSales >= 250000 THEN 4
            WHEN CityTotalSales >= 100000 THEN 3
            WHEN CityTotalSales >= 50000 THEN 2
            ELSE 1
        END AS MarketSizeScore,
        
        -- Profitability Score (1-5 scale based on profit margin)
        CASE 
            WHEN CityProfitMarginPct >= 30 THEN 5
            WHEN CityProfitMarginPct >= 25 THEN 4
            WHEN CityProfitMarginPct >= 20 THEN 3
            WHEN CityProfitMarginPct >= 15 THEN 2
            ELSE 1
        END AS ProfitabilityScore,
        
        -- Competition Score (5 = low competition, 1 = high competition)
        CASE 
            WHEN ExistingStores = 0 AND CompetingResellers <= 1 THEN 5
            WHEN ExistingStores = 0 AND CompetingResellers <= 3 THEN 4
            WHEN ExistingStores <= 1 AND CompetingResellers <= 3 THEN 3
            WHEN ExistingStores <= 2 THEN 2
            ELSE 1
        END AS CompetitionScore,
        
        -- Market Validation Score (based on online/reseller success)
        CASE 
            WHEN HasOnlineDemand = 1 AND HasResellerPresence = 1 THEN 5
            WHEN HasOnlineDemand = 1 AND OnlineSales >= 50000 THEN 4
            WHEN HasResellerPresence = 1 AND ResellerSales >= 50000 THEN 4
            WHEN HasOnlineDemand = 1 OR HasResellerPresence = 1 THEN 3
            ELSE 1
        END AS MarketValidationScore,
        
        -- Store Opportunity Priority
        CASE 
            WHEN HasStorePresence = 0 AND (OnlineSales + ResellerSales) >= 100000 THEN 'HIGH PRIORITY'
            WHEN HasStorePresence = 0 AND (OnlineSales + ResellerSales) >= 50000 THEN 'MEDIUM PRIORITY'
            WHEN HasStorePresence = 0 AND (OnlineSales + ResellerSales) >= 25000 THEN 'LOW PRIORITY'
            WHEN HasStorePresence = 1 AND StoreSales < (OnlineSales + ResellerSales) THEN 'EXPANSION OPPORTUNITY'
            ELSE 'NOT RECOMMENDED'
        END AS ExpansionPriority
        
    FROM city_totals
)

-- Final output with comprehensive analysis
SELECT 
    -- Location Details
    Country,
    StateProvince,
    City,
    
    -- Financial Performance
    CityTotalSales,
    CityTotalProfit,
    CityTotalQuantity,
    CityTotalTransactions,
    CityAvgTransactionValue,
    CityProfitMarginPct,
    
    -- Channel Performance
    COALESCE(StoreSales, 0) AS StoreSales,
    COALESCE(OnlineSales, 0) AS OnlineSales,
    COALESCE(ResellerSales, 0) AS ResellerSales,
    ROUND((COALESCE(OnlineSales, 0) + COALESCE(ResellerSales, 0)), 2) AS NonStoreSales,
    
    -- Market Structure
    COALESCE(ExistingStores, 0) AS ExistingStores,
    COALESCE(CompetingResellers, 0) AS CompetingResellers,
    HasStorePresence,
    HasOnlineDemand,
    HasResellerPresence,
    
    -- Scoring System
    MarketSizeScore,
    ProfitabilityScore,
    CompetitionScore,
    MarketValidationScore,
    ROUND((MarketSizeScore + ProfitabilityScore + CompetitionScore + MarketValidationScore) / 4.0, 2) AS OverallOpportunityScore,
    
    -- Strategic Recommendation
    ExpansionPriority,
    
    -- Business Rationale
    CASE 
        WHEN ExpansionPriority = 'HIGH PRIORITY' THEN 
            'Strong market validation with $' || ROUND((OnlineSales + ResellerSales)/1000, 0) || 'K in non-store sales. No physical store presence.'
        WHEN ExpansionPriority = 'MEDIUM PRIORITY' THEN 
            'Moderate market demand with $' || ROUND((OnlineSales + ResellerSales)/1000, 0) || 'K in non-store sales. Consider store opening.'
        WHEN ExpansionPriority = 'LOW PRIORITY' THEN 
            'Limited market validation but some demand exists. Monitor for growth.'
        WHEN ExpansionPriority = 'EXPANSION OPPORTUNITY' THEN 
            'Existing store underperforming vs online/reseller channels. Consider expansion or optimization.'
        ELSE 
            'Insufficient market validation or high competition. Not recommended for store opening.'
    END AS BusinessRationale,
    
    -- Market Characteristics
    CASE 
        WHEN CompetingResellers = 0 THEN 'Untapped Market'
        WHEN CompetingResellers <= 2 THEN 'Low Competition'
        WHEN CompetingResellers <= 5 THEN 'Moderate Competition'
        ELSE 'High Competition'
    END AS CompetitionLevel,
    
    CASE 
        WHEN CityTotalSales >= 250000 THEN 'Large Market'
        WHEN CityTotalSales >= 100000 THEN 'Medium Market'
        WHEN CityTotalSales >= 50000 THEN 'Small Market'
        ELSE 'Micro Market'
    END AS MarketSize

FROM market_analysis
WHERE CityTotalSales > 0  -- Only include cities with actual sales data

ORDER BY 
    -- Prioritize by expansion priority and opportunity score
    CASE ExpansionPriority
        WHEN 'HIGH PRIORITY' THEN 1
        WHEN 'MEDIUM PRIORITY' THEN 2
        WHEN 'EXPANSION OPPORTUNITY' THEN 3
        WHEN 'LOW PRIORITY' THEN 4
        ELSE 5
    END,
    OverallOpportunityScore DESC,
    CityTotalSales DESC;