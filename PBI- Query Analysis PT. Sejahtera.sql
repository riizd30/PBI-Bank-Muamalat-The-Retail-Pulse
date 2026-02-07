-- Check-in One By One Tabel

SELECT * FROM `pbi-bank-mualmalat.BankMuamalat.BM-Cust` LIMIT 1000;
SELECT * FROM `pbi-bank-mualmalat.BankMuamalat.BM-Ord` LIMIT 1000;
SELECT * FROM `pbi-bank-mualmalat.BankMuamalat.BM-ProCate` LIMIT 1000;
SELECT * FROM `pbi-bank-mualmalat.BankMuamalat.BM-Prod` LIMIT 1000;


-- Cleaning Customer data: removing 'mailto:' tags, trimming whitespace,
-- handling missing states, and removing duplicates/nulls.

CREATE TABLE `pbi-bank-muamalat.BankMuamalat.BM-Cust_clean` AS
SELECT 
    DISTINCT CustomerID,
    REGEXP_REPLACE(CustomerEmail, r'#mailto:.*?#', '') CustomerEmail_Clean,
    TRIM(CustomerCity) CustomerCity,
    COALESCE(TRIM(CustomerState), 'Unknown') CustomerState,
    FirstName,
    LastName,
    CustomerPhone,
    CustomerAddress,
    CustomerZip
FROM `pbi-bank-muamalat.BankMuamalat.BM-Cust`
WHERE CustomerID IS NOT NULL;


-- Standardizing Product data: Converting Price to FLOAT64 to ensure numerical
-- consistency and enable precise aggregation in the visualization layer.
CREATE TABLE `pbi-bank-muamalat.BankMuamalat.BM-Prod_clean` AS
SELECT
    ProdNumber,
    ProdName,
    Category,
    -- Using SAFE_CAST to FLOAT64 for calculation efficiency and dashboard compatibility
    SAFE_CAST(Price AS FLOAT64) AS Price
FROM `pbi-bank-muamalat.BankMuamalat.BM-Prod`
WHERE ProdNumber IS NOT NULL;


-- Consolidating all entities into a master table with 10 columns
-- Additional columns are placed at the end to maintain task requirements
CREATE OR REPLACE TABLE `pbi-bank-muamalat.BankMuamalat.Master_Sales_Table` AS
SELECT
    o.Date AS order_date,
    pc.CategoryName AS category_name,
    p.ProdName AS product_name,
    p.Price AS product_price,
    o.Quantity AS order_qty,
    -- Business Metric: Revenue
    (p.Price * o.Quantity) AS total_sales,
    c.CustomerEmail_Clean AS cust_email,
    c.CustomerCity AS cust_city,
    -- Additional columns at the end
    c.CustomerState AS cust_state,
    c.CustomerPhone AS cust_phone
FROM `pbi-bank-muamalat.BankMuamalat.BM-Ord` o
LEFT JOIN `pbi-bank-muamalat.BankMuamalat.BM-Cust_clean` c ON o.CustomerID = c.CustomerID
LEFT JOIN `pbi-bank-muamalat.BankMuamalat.BM-Prod_clean` p ON o.ProdNumber = p.ProdNumber
LEFT JOIN `pbi-bank-muamalat.BankMuamalat.BM-ProCate` pc ON p.Category = pc.CategoryID
-- Ensuring data is sorted from the earliest date
ORDER BY order_date ASC;