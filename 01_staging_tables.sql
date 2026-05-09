--DROP TABLE IF EXISTS TargetDataChannel
-- Channel table
CREATE TABLE Staging_Channel (
    ChannelID Integer PRIMARY KEY,
    ChannelCategoryID Integer,
    Channel VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);

-- ChannelCategory table
CREATE TABLE Staging_ChannelCategory (
    ChannelCategoryID INTEGER PRIMARY KEY,
    ChannelCategory VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);


-- Customer table
CREATE TABLE Staging_Customer (
    CustomerID VARCHAR(255) PRIMARY KEY,
    SubSegmentID Integer,
    FirstName VARCHAR(255),
    LastName VARCHAR(255),
    Gender VARCHAR(255),
    EmailAddress VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    StateProvince VARCHAR(255),
    Country VARCHAR(255),
    PostalCode VARCHAR(255),
    PhoneNumber VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255)
);

-- Product table
CREATE TABLE Staging_Product (
    ProductID INTEGER PRIMARY KEY,
    ProductTypeID INTEGER,
    Product VARCHAR(255),
    Color VARCHAR(255),
    Style VARCHAR(255),
    UnitOfMeasureID INTEGER,
    Weight FLOAT,
    Price FLOAT,
    Cost FLOAT,
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255),
    WholesalePrice FLOAT
);

-- ProductCategory table
CREATE TABLE Staging_ProductCategory (
    ProductCategoryID INTEGER PRIMARY KEY,
    ProductCategory VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255)
);

-- ProductType table
CREATE TABLE Staging_ProductType (
    ProductTypeID INTEGER PRIMARY KEY,
    ProductCategoryID INTEGER,
    ProductType VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255)
);

-- Reseller table
CREATE TABLE Staging_Reseller (
    ResellerID VARCHAR(255) PRIMARY KEY,
    Contact VARCHAR(255),
    EmailAddress VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    StateProvince VARCHAR(255),
    Country VARCHAR(255),
    PostalCode VARCHAR(255),
    PhoneNumber VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255),
    ResellerName VARCHAR(255)
);

-- SalesDetail table
CREATE TABLE Staging_SalesDetail (
    SalesDetailID INTEGER PRIMARY KEY,
    SalesHeaderID INTEGER,
    ProductID INTEGER,
    SalesQuantity INTEGER,
    SalesAmount FLOAT,
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);

-- SalesHeader table
CREATE TABLE Staging_SalesHeader (
    SalesHeaderID INTEGER PRIMARY KEY,
    Date DATE,
    ChannelID INTEGER,
    StoreID INTEGER,
    CustomerID VARCHAR(255),
    ResellerID VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);
UPDATE Staging_SalesHeader 
SET Date = 
    CASE 
        WHEN Date LIKE '0013-%' THEN REPLACE(Date, '0013-', '2013-')
        WHEN Date LIKE '0014-%' THEN REPLACE(Date, '0014-', '2014-')
        WHEN Date LIKE '0015-%' THEN REPLACE(Date, '0015-', '2015-')
        WHEN Date LIKE '0012-%' THEN REPLACE(Date, '0012-', '2012-')
        ELSE Date
    END
WHERE Date LIKE '00%';


SELECT*FROM Staging_SalesHeader;

-- Store table
CREATE TABLE Staging_Store (
    StoreID INTEGER PRIMARY KEY,
    SubSegmentID INTEGER,
    StoreNumber INTEGER,
    StoreManager VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    StateProvince VARCHAR(255),
    Country VARCHAR(255),
    PostalCode VARCHAR(255),
    PhoneNumber VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);

-- Target Data Channel Reseller and Store table
CREATE TABLE Staging_TargetDataChannel (
    Year INTEGER,
    ChannelName VARCHAR(255),
    TargetName VARCHAR(255),
    TargetSalesAmount INTEGER
);

-- Target Data Product table
CREATE TABLE Staging_TargetDataProduct (
    ProductID INTEGER,
    Product VARCHAR(255),
    Year INTEGER,
    SalesQuantityTarget INTEGER
);

Select * from Staging_Store;

Select * from Staging_SalesDetail;

Select * from Staging_TargetDataChannel;