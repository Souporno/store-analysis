-- Step 1: Create the Fact_ProductSalesTarget table
CREATE OR REPLACE TABLE Fact_ProductSalesTarget (
    DimProductID INT NOT NULL, -- Assume DimProductID is INT in Dim_Product
    DimTargetDateID NUMBER(9) NOT NULL, -- Match with DATE_PKEY data type in DIM_DATE
    ProductTargetSalesQuantity INT NOT NULL,
    CONSTRAINT FK_Product FOREIGN KEY (DimProductID) REFERENCES Dim_Product(DimProductID),
    CONSTRAINT FK_TargetDate FOREIGN KEY (DimTargetDateID) REFERENCES DIM_DATE(DATE_PKEY)
);

-- Step 2: Insert data from staging tables
INSERT INTO Fact_ProductSalesTarget (
    DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
)
SELECT 
    p.DimProductID,
    d.DATE_PKEY AS DimTargetDateID,  -- This is NUMBER(9) type from DIM_DATE
    COALESCE(tp.SalesQuantityTarget, 0) AS ProductTargetSalesQuantity  -- Using COALESCE to handle NULLs
FROM 
    Staging_TargetDataProduct tp
JOIN 
    Dim_Product p ON tp.ProductID = p.ProductID
JOIN 
    DIM_DATE d ON tp.Year = d.YEAR  -- Joining by year since target is annual
                  AND d.MONTH_NUM_IN_YEAR = 1  -- Using January as the representative month
                  AND d.DAY_NUM_IN_MONTH = 1;  -- Using first day of month

--Step 3: Verify
SELECT * FROM Fact_ProductSalesTarget

-- Create Fact_SRCSalesTarget table (Store, Reseller, Channel Sales Target)
CREATE OR REPLACE TABLE Fact_SRCSalesTarget (
    DimStoreID INT,
    DimResellerID INT,
    DimChannelID INT,
    DimTargetDateID NUMBER(9) NOT NULL,  -- Match with DATE_PKEY in DIM_DATE
    SalesTargetAmount FLOAT NOT NULL,
    CONSTRAINT FK_SRC_Store FOREIGN KEY (DimStoreID) REFERENCES Dim_Store(DimStoreID),
    CONSTRAINT FK_SRC_Reseller FOREIGN KEY (DimResellerID) REFERENCES Dim_Reseller(DimResellerID),
    CONSTRAINT FK_SRC_Channel FOREIGN KEY (DimChannelID) REFERENCES Dim_Channel(DimChannelID),
    CONSTRAINT FK_SRC_TargetDate FOREIGN KEY (DimTargetDateID) REFERENCES DIM_DATE(DATE_PKEY)
);

-- Insert data from staging tables
INSERT INTO Fact_SRCSalesTarget (
    DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
)
SELECT 
    CASE WHEN tdc.TargetName = 'Store' THEN s.DimStoreID ELSE -1 END AS DimStoreID,
    CASE WHEN tdc.TargetName = 'Reseller' THEN r.DimResellerID ELSE -1 END AS DimResellerID,
    COALESCE(c.DimChannelID, -1) AS DimChannelID,
    d.DATE_PKEY AS DimTargetDateID,
    COALESCE(tdc.TargetSalesAmount, 0) AS SalesTargetAmount
FROM 
    Staging_TargetDataChannel tdc
LEFT JOIN 
    Dim_Channel c ON tdc.ChannelName = c.ChannelName
LEFT JOIN 
    Dim_Store s ON tdc.TargetName = 'Store'
LEFT JOIN 
    Dim_Reseller r ON tdc.TargetName = 'Reseller'
JOIN 
    DIM_DATE d ON tdc.Year = d.YEAR
                AND d.MONTH_NUM_IN_YEAR = 1
                AND d.DAY_NUM_IN_MONTH = 1;

--Step 3: Verify
SELECT * FROM Fact_SRCSalesTarget

--DROP TABLE Fact_SRCSalesTarget;


--DELETE FROM Fact_SalesActual;

-- Drop existing table if it exists
DROP TABLE IF EXISTS Fact_SalesActual;

-- Step 1: Create Fact_SalesActual table
CREATE OR REPLACE TABLE Fact_SalesActual (
    DimProductID INT NOT NULL,
    DimStoreID INT NOT NULL,
    DimResellerID INT NOT NULL,
    DimCustomerID INT NOT NULL,
    DimChannelID INT NOT NULL,
    DimSaleDateID NUMBER(9) NOT NULL,
    DimLocationID INT NOT NULL,
    SalesHeaderID INT,
    SalesDetailID INT,
    SaleAmount FLOAT NOT NULL,
    SaleQuantity INT NOT NULL,
    SaleUnitPrice FLOAT NOT NULL,
    SaleExtendedCost FLOAT NOT NULL,
    SaleTotalProfit FLOAT NOT NULL,
    CONSTRAINT FK_Sales_Product FOREIGN KEY (DimProductID) REFERENCES Dim_Product(DimProductID),
    CONSTRAINT FK_Sales_Store FOREIGN KEY (DimStoreID) REFERENCES Dim_Store(DimStoreID),
    CONSTRAINT FK_Sales_Reseller FOREIGN KEY (DimResellerID) REFERENCES Dim_Reseller(DimResellerID),
    CONSTRAINT FK_Sales_Customer FOREIGN KEY (DimCustomerID) REFERENCES Dim_Customer(DimCustomerID),
    CONSTRAINT FK_Sales_Channel FOREIGN KEY (DimChannelID) REFERENCES Dim_Channel(DimChannelID),
    CONSTRAINT FK_Sales_Date FOREIGN KEY (DimSaleDateID) REFERENCES DIM_DATE(DATE_PKEY),
    CONSTRAINT FK_Sales_Location FOREIGN KEY (DimLocationID) REFERENCES Dim_Location(DimLocationID)
);

-- Step 2: Insert with corrected date logic for the fixed format
INSERT INTO Fact_SalesActual (
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
)
SELECT 
    COALESCE(p.DimProductID, -1),
    CASE WHEN sh.StoreID IS NOT NULL THEN COALESCE(s.DimStoreID, -1) ELSE -1 END,
    CASE WHEN sh.ResellerID IS NOT NULL THEN COALESCE(r.DimResellerID, -1) ELSE -1 END,
    CASE WHEN sh.CustomerID IS NOT NULL THEN COALESCE(c.DimCustomerID, -1) ELSE -1 END,
    COALESCE(ch.DimChannelID, -1),
    COALESCE(dd.DATE_PKEY, 20130101),
    COALESCE(
        CASE 
            WHEN sh.StoreID IS NOT NULL THEN s.DimLocationID
            WHEN sh.ResellerID IS NOT NULL THEN r.DimLocationID
            WHEN sh.CustomerID IS NOT NULL THEN c.DimLocationID
            ELSE -1
        END, 
        -1
    ),
    sh.SalesHeaderID,
    sd.SalesDetailID,
    COALESCE(sd.SalesAmount, 0),
    COALESCE(sd.SalesQuantity, 0),
    CASE 
        WHEN COALESCE(sd.SalesQuantity, 0) = 0 THEN 0 
        ELSE COALESCE(sd.SalesAmount, 0) / COALESCE(sd.SalesQuantity, 1) 
    END,
    COALESCE(p.cost * sd.SalesQuantity, 0),
    COALESCE(sd.SalesAmount, 0) - COALESCE(p.cost * sd.SalesQuantity, 0)
FROM 
    Staging_SalesDetail sd
JOIN 
    Staging_SalesHeader sh ON sd.SalesHeaderID = sh.SalesHeaderID
LEFT JOIN 
    Dim_Product p ON sd.ProductID = p.ProductID
LEFT JOIN 
    Dim_Store s ON sh.StoreID = s.StoreID
LEFT JOIN 
    Dim_Reseller r ON sh.ResellerID = r.ResellerID
LEFT JOIN 
    Dim_Customer c ON sh.CustomerID = c.CustomerID
LEFT JOIN 
    Dim_Channel ch ON sh.ChannelID = ch.ChannelID
LEFT JOIN 
    (
        SELECT DISTINCT DATE_PKEY 
        FROM DIM_DATE
    ) dd 
    ON (
        -- FIXED: Handle the corrected YYYY-MM-DD format from Staging_SalesHeader
        CASE 
            WHEN sh.Date IS NOT NULL THEN
                TRY_TO_NUMBER(
                    REPLACE(REPLACE(sh.Date, '-', ''), ' ', '')  -- Convert YYYY-MM-DD to YYYYMMDD
                )
            ELSE NULL
        END
    ) = dd.DATE_PKEY;

--Step 3: Verify
SELECT * FROM Fact_SalesActual


















-- First, truncate the existing data
TRUNCATE TABLE Fact_SRCSalesTarget;

-- Insert data with proper parsing of TargetName
INSERT INTO Fact_SRCSalesTarget (
    DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
)
SELECT 
    -- Parse Store targets (format: "Store Number X")
    CASE 
        WHEN tdc.TargetName LIKE 'Store Number %' THEN 
            COALESCE(s.DimStoreID, -1)
        ELSE -1 
    END AS DimStoreID,
    
    -- Match Reseller targets by name
    CASE 
        WHEN tdc.TargetName NOT LIKE 'Store Number %' 
         AND tdc.TargetName != 'Customer Sales'
         AND r.DimResellerID IS NOT NULL THEN 
            r.DimResellerID
        ELSE -1 
    END AS DimResellerID,
    
    -- Channel ID
    COALESCE(c.DimChannelID, -1) AS DimChannelID,
    
    -- Target Date (January 1st of the target year)
    d.DATE_PKEY AS DimTargetDateID,
    
    -- Target Amount
    COALESCE(tdc.TargetSalesAmount, 0) AS SalesTargetAmount
    
FROM Staging_TargetDataChannel tdc

-- Join to get Channel dimension
LEFT JOIN Dim_Channel c 
    ON UPPER(TRIM(tdc.ChannelName)) = UPPER(TRIM(c.ChannelName))
    
-- Join to get Store dimension (extract store number from "Store Number X")
LEFT JOIN Dim_Store s 
    ON tdc.TargetName LIKE 'Store Number %' 
    AND TRY_TO_NUMBER(REPLACE(tdc.TargetName, 'Store Number ', '')) = s.StoreNumber
    
-- Join to get Reseller dimension by matching reseller names
LEFT JOIN Dim_Reseller r 
    ON UPPER(TRIM(tdc.TargetName)) = UPPER(TRIM(r.ResellerName))
    AND tdc.TargetName NOT LIKE 'Store Number %'
    AND tdc.TargetName != 'Customer Sales'
    
-- Join to get the date dimension
JOIN DIM_DATE d 
    ON tdc.Year = d.YEAR
    AND d.MONTH_NUM_IN_YEAR = 1  -- January
    AND d.DAY_NUM_IN_MONTH = 1;  -- 1st day

-- Verify the results
SELECT 
    'Store Targets' as TargetType,
    COUNT(*) as RecordCount,
    SUM(SalesTargetAmount) as TotalAmount
FROM Fact_SRCSalesTarget
WHERE DimStoreID != -1

UNION ALL

SELECT 
    'Reseller Targets' as TargetType,
    COUNT(*) as RecordCount,
    SUM(SalesTargetAmount) as TotalAmount
FROM Fact_SRCSalesTarget
WHERE DimResellerID != -1

UNION ALL

SELECT 
    'Channel Only Targets' as TargetType,
    COUNT(*) as RecordCount,
    SUM(SalesTargetAmount) as TotalAmount
FROM Fact_SRCSalesTarget
WHERE DimStoreID = -1 AND DimResellerID = -1;

-- Check specific stores 10 and 21
SELECT 
    s.StoreNumber,
    s.StoreManager,
    d.YEAR,
    f.SalesTargetAmount,
    c.ChannelName
FROM Fact_SRCSalesTarget f
JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
JOIN Dim_Channel c ON f.DimChannelID = c.DimChannelID
JOIN DIM_DATE d ON f.DimTargetDateID = d.DATE_PKEY
WHERE s.StoreNumber IN (10, 21)
ORDER BY s.StoreNumber, d.YEAR;