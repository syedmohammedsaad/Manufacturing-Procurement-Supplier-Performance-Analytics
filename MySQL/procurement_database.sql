CREATE DATABASE procurement_analytics;
USE procurement_analytics;
SHOW DATABASES;

USE procurement_analytics;

-- Suppliers
CREATE TABLE Suppliers (
    SupplierID VARCHAR(10) PRIMARY KEY,
    SupplierName VARCHAR(100),
    SupplierRegion VARCHAR(50),
    SupplierType VARCHAR(50),
    ContactEmail VARCHAR(100),
    StandardLeadTimeDays INT,
    SupplierStatus VARCHAR(30)
);

-- Materials
CREATE TABLE Materials (
    MaterialID VARCHAR(10) PRIMARY KEY,
    MaterialName VARCHAR(100),
    MaterialCategory VARCHAR(50),
    UnitOfMeasure VARCHAR(20),
    StandardUnitCostINR DECIMAL(12,2)
);

-- Purchase Orders
CREATE TABLE Purchase_Orders (
    PO_ID VARCHAR(15) PRIMARY KEY,
    PO_Date DATE,
    SupplierID VARCHAR(10),
    MaterialID VARCHAR(10),
    Order_Quantity INT,
    Unit_Price_INR DECIMAL(12,2),
    Total_Amount_INR DECIMAL(15,2),
    Payment_Status VARCHAR(30),

    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (MaterialID) REFERENCES Materials(MaterialID)
);

-- Deliveries
CREATE TABLE Deliveries (
    DeliveryID VARCHAR(15) PRIMARY KEY,
    PO_ID VARCHAR(15),
    Expected_Delivery_Date DATE,
    Actual_Delivery_Date DATE,
    Ordered_Quantity INT,
    Received_Quantity INT,
    Delay_Days INT,
    Delivery_Status VARCHAR(30),

    FOREIGN KEY (PO_ID) REFERENCES Purchase_Orders(PO_ID)
);

-- Quality Inspection
CREATE TABLE Quality_Inspection (
    InspectionID VARCHAR(15) PRIMARY KEY,
    PO_ID VARCHAR(15),
    Inspection_Date DATE,
    Inspected_Quantity INT,
    Accepted_Quantity INT,
    Defective_Quantity INT,
    Defect_Rate_Percent DECIMAL(6,2),

    FOREIGN KEY (PO_ID) REFERENCES Purchase_Orders(PO_ID)
);

USE procurement_analytics;

LOAD DATA LOCAL INFILE 'C:/Users/THIS-PC/OneDrive/Desktop/Manufacturing Procurement & Supplier Performance Analytics/Dataset/Purchase_Orders.csv'
INTO TABLE purchase_orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    PO_ID,
    PO_Date,
    SupplierID,
    MaterialID,
    Order_Quantity,
    Unit_Price_INR,
    Total_Amount_INR,
    Payment_Status
);

SELECT COUNT(*) AS Total_Purchase_Orders
FROM purchase_orders;

LOAD DATA LOCAL INFILE 'C:/Users/THIS-PC/OneDrive/Desktop/Manufacturing Procurement & Supplier Performance Analytics/Dataset/Deliveries.csv'
INTO TABLE deliveries
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    DeliveryID,
    PO_ID,
    Expected_Delivery_Date,
    Actual_Delivery_Date,
    Ordered_Quantity,
    Received_Quantity,
    Delay_Days,
    Delivery_Status
);

SELECT COUNT(*) AS Total_Deliveries
FROM deliveries;

LOAD DATA LOCAL INFILE 'C:/Users/THIS-PC/OneDrive/Desktop/Manufacturing Procurement & Supplier Performance Analytics/Dataset/Quality_Inspection.csv'
INTO TABLE quality_inspection
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    InspectionID,
    PO_ID,
    Inspection_Date,
    Inspected_Quantity,
    Accepted_Quantity,
    Defective_Quantity,
    Defect_Rate_Percent
);

SELECT COUNT(*) AS Total_Quality_Inspections
FROM quality_inspection;

-- Calculate Total Procurement Spend
SELECT
    SUM(Total_Amount_INR) AS Total_Procurement_Spend
FROM purchase_orders;

-- Count Total Purchase Orders
SELECT
    COUNT(PO_ID) AS Total_Purchase_Orders
FROM purchase_orders;

-- Calculate Total Quantity Ordered
SELECT
    SUM(Order_Quantity) AS Total_Quantity_Ordered
FROM purchase_orders;

-- Calculate Average Purchase Order Value
SELECT
    ROUND(AVG(Total_Amount_INR), 2) AS Average_PO_Value
FROM purchase_orders;

-- Analyse Purchase Orders by Payment Status
SELECT
    Payment_Status,
    COUNT(PO_ID) AS Total_Orders,
    SUM(Total_Amount_INR) AS Total_Amount_INR
FROM purchase_orders
GROUP BY Payment_Status;

-- Calculate Monthly Procurement Spend
SELECT
    DATE_FORMAT(PO_Date, '%Y-%m') AS Purchase_Month,
    COUNT(PO_ID) AS Total_Orders,
    SUM(Total_Amount_INR) AS Monthly_Spend
FROM purchase_orders
GROUP BY DATE_FORMAT(PO_Date, '%Y-%m')
ORDER BY Purchase_Month;

-- Calculate Procurement Spend by Supplier
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(p.PO_ID) AS Total_Orders,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Total_Procurement_Spend DESC;

-- Calculate Supplier-Wise Delivery Performance
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(d.DeliveryID) AS Total_Deliveries,
    SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END) AS On_Time_Deliveries,
    SUM(CASE WHEN d.Delivery_Status = 'Delayed' THEN 1 ELSE 0 END) AS Delayed_Deliveries,
    ROUND(
        SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.DeliveryID), 2
    ) AS On_Time_Delivery_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY On_Time_Delivery_Percentage DESC;

-- Calculate Supplier-Wise Quality Performance
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(q.Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(q.Accepted_Quantity) AS Total_Accepted_Quantity,
    SUM(q.Defective_Quantity) AS Total_Defective_Quantity,
    ROUND(
        SUM(q.Defective_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Defect_Rate_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Defect_Rate_Percentage ASC;

-- Calculate Procurement Spend by Material Category
SELECT
    m.MaterialCategory,
    COUNT(p.PO_ID) AS Total_Purchase_Orders,
    SUM(p.Order_Quantity) AS Total_Quantity_Ordered,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
FROM materials m
JOIN purchase_orders p
    ON m.MaterialID = p.MaterialID
GROUP BY
    m.MaterialCategory
ORDER BY Total_Procurement_Spend DESC;

-- Calculate Procurement Spend by Supplier Region
SELECT
    s.SupplierRegion,
    COUNT(p.PO_ID) AS Total_Purchase_Orders,
    COUNT(DISTINCT s.SupplierID) AS Total_Suppliers,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierRegion
ORDER BY Total_Procurement_Spend DESC;

-- Calculate Average Delivery Delay by Supplier
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(d.DeliveryID) AS Total_Deliveries,
    ROUND(AVG(d.Delay_Days), 2) AS Average_Delay_Days,
    MAX(d.Delay_Days) AS Maximum_Delay_Days
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Average_Delay_Days DESC;

-- Calculate Delivery Status Summary
SELECT
    Delivery_Status,
    COUNT(DeliveryID) AS Total_Deliveries,
    ROUND(
        COUNT(DeliveryID) * 100.0 /
        (SELECT COUNT(*) FROM deliveries), 2
    ) AS Delivery_Percentage
FROM deliveries
GROUP BY Delivery_Status
ORDER BY Total_Deliveries DESC;

-- Calculate Overall Quality Inspection Summary
SELECT
    SUM(Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(Accepted_Quantity) AS Total_Accepted_Quantity,
    SUM(Defective_Quantity) AS Total_Defective_Quantity,
    ROUND(
        SUM(Defective_Quantity) * 100.0 /
        NULLIF(SUM(Inspected_Quantity), 0), 2
    ) AS Overall_Defect_Rate_Percentage
FROM quality_inspection;

-- Calculate Monthly Delivery Performance
SELECT
    DATE_FORMAT(Expected_Delivery_Date, '%Y-%m') AS Delivery_Month,
    COUNT(DeliveryID) AS Total_Deliveries,
    SUM(CASE WHEN Delivery_Status = 'On Time' THEN 1 ELSE 0 END) AS On_Time_Deliveries,
    SUM(CASE WHEN Delivery_Status = 'Delayed' THEN 1 ELSE 0 END) AS Delayed_Deliveries,
    ROUND(
        SUM(CASE WHEN Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(DeliveryID), 2
    ) AS On_Time_Delivery_Percentage
FROM deliveries
GROUP BY DATE_FORMAT(Expected_Delivery_Date, '%Y-%m')
ORDER BY Delivery_Month;

-- Identify Top 10 Suppliers by Procurement Spend
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(p.PO_ID) AS Total_Orders,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Total_Procurement_Spend DESC
LIMIT 10;

-- Analyse Payment Status by Supplier
SELECT
    s.SupplierID,
    s.SupplierName,
    p.Payment_Status,
    COUNT(p.PO_ID) AS Total_Orders,
    SUM(p.Total_Amount_INR) AS Total_Amount_INR
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName,
    p.Payment_Status
ORDER BY
    s.SupplierID,
    Total_Amount_INR DESC;
    
-- Identify Suppliers with Highest Pending Payments
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(p.PO_ID) AS Pending_Orders,
    SUM(p.Total_Amount_INR) AS Pending_Amount_INR
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
WHERE p.Payment_Status = 'Pending'
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Pending_Amount_INR DESC
LIMIT 10;

-- Calculate Total Paid, Pending and Partially Paid Amounts
SELECT
    Payment_Status,
    COUNT(PO_ID) AS Total_Orders,
    SUM(Total_Amount_INR) AS Total_Amount_INR,
    ROUND(
        SUM(Total_Amount_INR) * 100.0 /
        (SELECT SUM(Total_Amount_INR) FROM purchase_orders), 2
    ) AS Amount_Percentage
FROM purchase_orders
GROUP BY Payment_Status
ORDER BY Total_Amount_INR DESC;

-- Identify Top 10 Materials by Procurement Spend
SELECT
    m.MaterialID,
    m.MaterialName,
    m.MaterialCategory,
    SUM(p.Order_Quantity) AS Total_Quantity_Ordered,
    COUNT(p.PO_ID) AS Total_Purchase_Orders,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
FROM materials m
JOIN purchase_orders p
    ON m.MaterialID = p.MaterialID
GROUP BY
    m.MaterialID,
    m.MaterialName,
    m.MaterialCategory
ORDER BY Total_Procurement_Spend DESC
LIMIT 10;

-- Calculate Procurement Spend by Material Category and Payment Status
SELECT
    m.MaterialCategory,
    p.Payment_Status,
    COUNT(p.PO_ID) AS Total_Orders,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
FROM materials m
JOIN purchase_orders p
    ON m.MaterialID = p.MaterialID
GROUP BY
    m.MaterialCategory,
    p.Payment_Status
ORDER BY
    m.MaterialCategory,
    Total_Procurement_Spend DESC;
    
-- Calculate Supplier-Wise Average Purchase Order Value
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(p.PO_ID) AS Total_Orders,
    ROUND(AVG(p.Total_Amount_INR), 2) AS Average_PO_Value,
    MAX(p.Total_Amount_INR) AS Highest_PO_Value,
    MIN(p.Total_Amount_INR) AS Lowest_PO_Value
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Average_PO_Value DESC;

-- Calculate Supplier-Wise Purchase Order Quantity
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(p.Order_Quantity) AS Total_Quantity_Ordered,
    ROUND(AVG(p.Order_Quantity), 2) AS Average_Order_Quantity,
    MAX(p.Order_Quantity) AS Maximum_Order_Quantity
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Total_Quantity_Ordered DESC;

-- Identify Suppliers with the Highest Defective Quantity
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(q.Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(q.Defective_Quantity) AS Total_Defective_Quantity,
    ROUND(
        SUM(q.Defective_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Defect_Rate_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Total_Defective_Quantity DESC
LIMIT 10;

-- Identify Suppliers with the Lowest On-Time Delivery Performance
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(d.DeliveryID) AS Total_Deliveries,
    SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END) AS On_Time_Deliveries,
    SUM(CASE WHEN d.Delivery_Status = 'Delayed' THEN 1 ELSE 0 END) AS Delayed_Deliveries,
    ROUND(
        SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.DeliveryID), 2
    ) AS On_Time_Delivery_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY On_Time_Delivery_Percentage ASC
LIMIT 10;

-- Calculate Supplier Performance Score
SELECT
    s.SupplierID,
    s.SupplierName,
    ROUND(
        SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.DeliveryID), 2
    ) AS On_Time_Delivery_Percentage,
    ROUND(
        SUM(q.Accepted_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Quality_Acceptance_Percentage,
    ROUND(
        (
            SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(d.DeliveryID)
            +
            SUM(q.Accepted_Quantity) * 100.0 /
            NULLIF(SUM(q.Inspected_Quantity), 0)
        ) / 2, 2
    ) AS Supplier_Performance_Score
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Supplier_Performance_Score DESC;

-- Identify Suppliers by Performance Category
SELECT
    s.SupplierID,
    s.SupplierName,
    ROUND(
        (
            SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(d.DeliveryID)
            +
            SUM(q.Accepted_Quantity) * 100.0 /
            NULLIF(SUM(q.Inspected_Quantity), 0)
        ) / 2, 2
    ) AS Supplier_Performance_Score,
    CASE
        WHEN (
            (
                SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                * 100.0 / COUNT(d.DeliveryID)
                +
                SUM(q.Accepted_Quantity) * 100.0 /
                NULLIF(SUM(q.Inspected_Quantity), 0)
            ) / 2
        ) >= 70 THEN 'Excellent'
        WHEN (
            (
                SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                * 100.0 / COUNT(d.DeliveryID)
                +
                SUM(q.Accepted_Quantity) * 100.0 /
                NULLIF(SUM(q.Inspected_Quantity), 0)
            ) / 2
        ) >= 60 THEN 'Good'
        WHEN (
            (
                SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                * 100.0 / COUNT(d.DeliveryID)
                +
                SUM(q.Accepted_Quantity) * 100.0 /
                NULLIF(SUM(q.Inspected_Quantity), 0)
            ) / 2
        ) >= 50 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS Performance_Category
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Supplier_Performance_Score DESC;

-- Count Suppliers by Performance Category
SELECT
    Performance_Category,
    COUNT(*) AS Total_Suppliers
FROM (
    SELECT
        s.SupplierID,
        CASE
            WHEN (
                (
                    SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                    * 100.0 / COUNT(d.DeliveryID)
                    +
                    SUM(q.Accepted_Quantity) * 100.0 /
                    NULLIF(SUM(q.Inspected_Quantity), 0)
                ) / 2
            ) >= 70 THEN 'Excellent'
            WHEN (
                (
                    SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                    * 100.0 / COUNT(d.DeliveryID)
                    +
                    SUM(q.Accepted_Quantity) * 100.0 /
                    NULLIF(SUM(q.Inspected_Quantity), 0)
                ) / 2
            ) >= 60 THEN 'Good'
            WHEN (
                (
                    SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                    * 100.0 / COUNT(d.DeliveryID)
                    +
                    SUM(q.Accepted_Quantity) * 100.0 /
                    NULLIF(SUM(q.Inspected_Quantity), 0)
                ) / 2
            ) >= 50 THEN 'Average'
            ELSE 'Needs Improvement'
        END AS Performance_Category
    FROM suppliers s
    JOIN purchase_orders p
        ON s.SupplierID = p.SupplierID
    JOIN deliveries d
        ON p.PO_ID = d.PO_ID
    JOIN quality_inspection q
        ON p.PO_ID = q.PO_ID
    GROUP BY s.SupplierID
) AS Supplier_Scores
GROUP BY Performance_Category
ORDER BY Total_Suppliers DESC;

-- Calculate Overall Supplier Performance Summary
SELECT
    COUNT(*) AS Total_Suppliers,
    ROUND(AVG(Supplier_Performance_Score), 2) AS Average_Performance_Score,
    MAX(Supplier_Performance_Score) AS Highest_Performance_Score,
    MIN(Supplier_Performance_Score) AS Lowest_Performance_Score
FROM (
    SELECT
        s.SupplierID,
        (
            SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(d.DeliveryID)
            +
            SUM(q.Accepted_Quantity) * 100.0 /
            NULLIF(SUM(q.Inspected_Quantity), 0)
        ) / 2 AS Supplier_Performance_Score
    FROM suppliers s
    JOIN purchase_orders p
        ON s.SupplierID = p.SupplierID
    JOIN deliveries d
        ON p.PO_ID = d.PO_ID
    JOIN quality_inspection q
        ON p.PO_ID = q.PO_ID
    GROUP BY s.SupplierID
) AS Supplier_Summary;

-- Rank Suppliers by Procurement Spend
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend,
    RANK() OVER (
        ORDER BY SUM(p.Total_Amount_INR) DESC
    ) AS Supplier_Rank
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Supplier_Rank;

-- Rank Suppliers by On-Time Delivery Performance
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(d.DeliveryID) AS Total_Deliveries,
    SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END) AS On_Time_Deliveries,
    ROUND(
        SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.DeliveryID), 2
    ) AS On_Time_Delivery_Percentage,
    RANK() OVER (
        ORDER BY
            SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(d.DeliveryID) DESC
    ) AS Delivery_Performance_Rank
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Delivery_Performance_Rank;

-- Rank Suppliers by Quality Acceptance Percentage
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(q.Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(q.Accepted_Quantity) AS Total_Accepted_Quantity,
    ROUND(
        SUM(q.Accepted_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Quality_Acceptance_Percentage,
    RANK() OVER (
        ORDER BY
            SUM(q.Accepted_Quantity) * 100.0 /
            NULLIF(SUM(q.Inspected_Quantity), 0) DESC
    ) AS Quality_Performance_Rank
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Quality_Performance_Rank;

-- Rank Suppliers by Overall Performance Score
SELECT
    s.SupplierID,
    s.SupplierName,
    ROUND(
        (
            SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(d.DeliveryID)
            +
            SUM(q.Accepted_Quantity) * 100.0 /
            NULLIF(SUM(q.Inspected_Quantity), 0)
        ) / 2, 2
    ) AS Supplier_Performance_Score,
    DENSE_RANK() OVER (
        ORDER BY
            (
                SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
                * 100.0 / COUNT(d.DeliveryID)
                +
                SUM(q.Accepted_Quantity) * 100.0 /
                NULLIF(SUM(q.Inspected_Quantity), 0)
            ) / 2 DESC
    ) AS Overall_Performance_Rank
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Overall_Performance_Rank;

-- Calculate Running Total of Procurement Spend
SELECT
    PO_ID,
    PO_Date,
    Total_Amount_INR,
    SUM(Total_Amount_INR) OVER (
        ORDER BY PO_Date, PO_ID
    ) AS Running_Total_Spend
FROM purchase_orders
ORDER BY PO_Date, PO_ID;

-- Calculate Running Monthly Procurement Spend
WITH Monthly_Spend AS (
    SELECT
        DATE_FORMAT(PO_Date, '%Y-%m') AS Purchase_Month,
        SUM(Total_Amount_INR) AS Monthly_Procurement_Spend
    FROM purchase_orders
    GROUP BY DATE_FORMAT(PO_Date, '%Y-%m')
)
SELECT
    Purchase_Month,
    Monthly_Procurement_Spend,
    SUM(Monthly_Procurement_Spend) OVER (
        ORDER BY Purchase_Month
    ) AS Running_Total_Spend
FROM Monthly_Spend
ORDER BY Purchase_Month;

-- Calculate Month-over-Month Procurement Spend Growth
WITH Monthly_Spend AS (
    SELECT
        DATE_FORMAT(PO_Date, '%Y-%m') AS Purchase_Month,
        SUM(Total_Amount_INR) AS Monthly_Procurement_Spend
    FROM purchase_orders
    GROUP BY DATE_FORMAT(PO_Date, '%Y-%m')
),
Previous_Month_Spend AS (
    SELECT
        Purchase_Month,
        Monthly_Procurement_Spend,
        LAG(Monthly_Procurement_Spend) OVER (
            ORDER BY Purchase_Month
        ) AS Previous_Month_Spend
    FROM Monthly_Spend
)
SELECT
    Purchase_Month,
    Monthly_Procurement_Spend,
    Previous_Month_Spend,
    ROUND(
        (Monthly_Procurement_Spend - Previous_Month_Spend)
        * 100.0 / NULLIF(Previous_Month_Spend, 0), 2
    ) AS Month_Over_Month_Growth_Percentage
FROM Previous_Month_Spend
ORDER BY Purchase_Month;

-- Compare Monthly Procurement Spend with Previous Year
WITH Monthly_Spend AS (
    SELECT
        YEAR(PO_Date) AS Purchase_Year,
        MONTH(PO_Date) AS Purchase_Month,
        SUM(Total_Amount_INR) AS Monthly_Procurement_Spend
    FROM purchase_orders
    GROUP BY
        YEAR(PO_Date),
        MONTH(PO_Date)
),
Previous_Year_Spend AS (
    SELECT
        Purchase_Year,
        Purchase_Month,
        Monthly_Procurement_Spend,
        LAG(Monthly_Procurement_Spend, 12) OVER (
            ORDER BY Purchase_Year, Purchase_Month
        ) AS Previous_Year_Spend
    FROM Monthly_Spend
)
SELECT
    Purchase_Year,
    Purchase_Month,
    Monthly_Procurement_Spend,
    Previous_Year_Spend,
    ROUND(
        (Monthly_Procurement_Spend - Previous_Year_Spend)
        * 100.0 / NULLIF(Previous_Year_Spend, 0), 2
    ) AS Year_Over_Year_Growth_Percentage
FROM Previous_Year_Spend
ORDER BY Purchase_Year, Purchase_Month;

-- Calculate Supplier Contribution to Total Procurement Spend
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(p.Total_Amount_INR) AS Supplier_Procurement_Spend,
    ROUND(
        SUM(p.Total_Amount_INR) * 100.0 /
        (SELECT SUM(Total_Amount_INR) FROM purchase_orders), 2
    ) AS Procurement_Contribution_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Procurement_Contribution_Percentage DESC;

-- Calculate Cumulative Procurement Spend Contribution by Supplier
WITH Supplier_Spend AS (
    SELECT
        s.SupplierID,
        s.SupplierName,
        SUM(p.Total_Amount_INR) AS Supplier_Procurement_Spend
    FROM suppliers s
    JOIN purchase_orders p
        ON s.SupplierID = p.SupplierID
    GROUP BY
        s.SupplierID,
        s.SupplierName
)
SELECT
    SupplierID,
    SupplierName,
    Supplier_Procurement_Spend,
    ROUND(
        SUM(Supplier_Procurement_Spend) OVER (
            ORDER BY Supplier_Procurement_Spend DESC
        ) * 100.0 /
        SUM(Supplier_Procurement_Spend) OVER (), 2
    ) AS Cumulative_Contribution_Percentage
FROM Supplier_Spend
ORDER BY Supplier_Procurement_Spend DESC;

-- Identify Top 20% Suppliers by Procurement Spend
WITH Supplier_Spend AS (
    SELECT
        s.SupplierID,
        s.SupplierName,
        SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
    FROM suppliers s
    JOIN purchase_orders p
        ON s.SupplierID = p.SupplierID
    GROUP BY
        s.SupplierID,
        s.SupplierName
),
Ranked_Suppliers AS (
    SELECT
        SupplierID,
        SupplierName,
        Total_Procurement_Spend,
        NTILE(5) OVER (
            ORDER BY Total_Procurement_Spend DESC
        ) AS Supplier_Group
    FROM Supplier_Spend
)
SELECT
    SupplierID,
    SupplierName,
    Total_Procurement_Spend,
    Supplier_Group
FROM Ranked_Suppliers
WHERE Supplier_Group = 1
ORDER BY Total_Procurement_Spend DESC;

-- Analyse Procurement Spend by Supplier Group
WITH Supplier_Spend AS (
    SELECT
        s.SupplierID,
        s.SupplierName,
        SUM(p.Total_Amount_INR) AS Total_Procurement_Spend
    FROM suppliers s
    JOIN purchase_orders p
        ON s.SupplierID = p.SupplierID
    GROUP BY
        s.SupplierID,
        s.SupplierName
),
Ranked_Suppliers AS (
    SELECT
        SupplierID,
        SupplierName,
        Total_Procurement_Spend,
        NTILE(5) OVER (
            ORDER BY Total_Procurement_Spend DESC
        ) AS Supplier_Group
    FROM Supplier_Spend
)
SELECT
    Supplier_Group,
    COUNT(SupplierID) AS Total_Suppliers,
    SUM(Total_Procurement_Spend) AS Group_Procurement_Spend,
    ROUND(
        SUM(Total_Procurement_Spend) * 100.0 /
        (SELECT SUM(Total_Amount_INR) FROM purchase_orders), 2
    ) AS Spend_Contribution_Percentage
FROM Ranked_Suppliers
GROUP BY Supplier_Group
ORDER BY Supplier_Group;

-- Identify Suppliers with Above-Average Procurement Spend
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(p.Total_Amount_INR) AS Supplier_Procurement_Spend
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
HAVING SUM(p.Total_Amount_INR) > (
    SELECT AVG(Supplier_Total)
    FROM (
        SELECT SUM(Total_Amount_INR) AS Supplier_Total
        FROM purchase_orders
        GROUP BY SupplierID
    ) AS Supplier_Averages
)
ORDER BY Supplier_Procurement_Spend DESC;

-- Identify Suppliers with Below-Average Procurement Spend
SELECT
    s.SupplierID,
    s.SupplierName,
    SUM(p.Total_Amount_INR) AS Supplier_Procurement_Spend
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierID,
    s.SupplierName
HAVING SUM(p.Total_Amount_INR) < (
    SELECT AVG(Supplier_Total)
    FROM (
        SELECT SUM(Total_Amount_INR) AS Supplier_Total
        FROM purchase_orders
        GROUP BY SupplierID
    ) AS Supplier_Averages
)
ORDER BY Supplier_Procurement_Spend ASC;

-- Calculate Average Procurement Spend by Supplier Region
SELECT
    s.SupplierRegion,
    COUNT(DISTINCT s.SupplierID) AS Total_Suppliers,
    ROUND(AVG(Supplier_Spend.Total_Spend), 2) AS Average_Procurement_Spend,
    SUM(Supplier_Spend.Total_Spend) AS Total_Regional_Spend
FROM suppliers s
JOIN (
    SELECT
        SupplierID,
        SUM(Total_Amount_INR) AS Total_Spend
    FROM purchase_orders
    GROUP BY SupplierID
) AS Supplier_Spend
    ON s.SupplierID = Supplier_Spend.SupplierID
GROUP BY s.SupplierRegion
ORDER BY Average_Procurement_Spend DESC;

-- Calculate Average Delivery Delay by Supplier Region
SELECT
    s.SupplierRegion,
    COUNT(DISTINCT s.SupplierID) AS Total_Suppliers,
    ROUND(AVG(d.Delay_Days), 2) AS Average_Delay_Days,
    MAX(d.Delay_Days) AS Maximum_Delay_Days
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
GROUP BY
    s.SupplierRegion
ORDER BY Average_Delay_Days DESC;

-- Calculate Quality Defect Rate by Material Category
SELECT
    m.MaterialCategory,
    SUM(q.Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(q.Accepted_Quantity) AS Total_Accepted_Quantity,
    SUM(q.Defective_Quantity) AS Total_Defective_Quantity,
    ROUND(
        SUM(q.Defective_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Defect_Rate_Percentage
FROM materials m
JOIN purchase_orders p
    ON m.MaterialID = p.MaterialID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    m.MaterialCategory
ORDER BY Defect_Rate_Percentage DESC;

-- Calculate Monthly Quality Defect Rate
SELECT
    DATE_FORMAT(Inspection_Date, '%Y-%m') AS Inspection_Month,
    SUM(Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(Defective_Quantity) AS Total_Defective_Quantity,
    ROUND(
        SUM(Defective_Quantity) * 100.0 /
        NULLIF(SUM(Inspected_Quantity), 0), 2
    ) AS Defect_Rate_Percentage
FROM quality_inspection
GROUP BY DATE_FORMAT(Inspection_Date, '%Y-%m')
ORDER BY Inspection_Month;

-- Identify Top 10 Months with the Highest Defect Rates
SELECT
    DATE_FORMAT(Inspection_Date, '%Y-%m') AS Inspection_Month,
    SUM(Inspected_Quantity) AS Total_Inspected_Quantity,
    SUM(Defective_Quantity) AS Total_Defective_Quantity,
    ROUND(
        SUM(Defective_Quantity) * 100.0 /
        NULLIF(SUM(Inspected_Quantity), 0), 2
    ) AS Defect_Rate_Percentage
FROM quality_inspection
GROUP BY DATE_FORMAT(Inspection_Date, '%Y-%m')
ORDER BY Defect_Rate_Percentage DESC
LIMIT 10;

-- Identify Purchase Orders with the Highest Defective Quantity
SELECT
    q.PO_ID,
    p.SupplierID,
    s.SupplierName,
    m.MaterialName,
    q.Inspected_Quantity,
    q.Accepted_Quantity,
    q.Defective_Quantity,
    q.Defect_Rate_Percent
FROM quality_inspection q
JOIN purchase_orders p
    ON q.PO_ID = p.PO_ID
JOIN suppliers s
    ON p.SupplierID = s.SupplierID
JOIN materials m
    ON p.MaterialID = m.MaterialID
ORDER BY q.Defective_Quantity DESC
LIMIT 10;

-- Identify Purchase Orders with the Highest Delivery Delays
SELECT
    d.PO_ID,
    p.SupplierID,
    s.SupplierName,
    d.Expected_Delivery_Date,
    d.Actual_Delivery_Date,
    d.Delay_Days,
    d.Delivery_Status
FROM deliveries d
JOIN purchase_orders p
    ON d.PO_ID = p.PO_ID
JOIN suppliers s
    ON p.SupplierID = s.SupplierID
ORDER BY d.Delay_Days DESC
LIMIT 10;

-- Calculate Supplier-Wise Delayed Order Percentage
SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(d.DeliveryID) AS Total_Deliveries,
    SUM(CASE
        WHEN d.Delivery_Status = 'Delayed' THEN 1
        ELSE 0
    END) AS Delayed_Deliveries,
    ROUND(
        SUM(CASE
            WHEN d.Delivery_Status = 'Delayed' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(d.DeliveryID), 2
    ) AS Delayed_Order_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
ORDER BY Delayed_Order_Percentage DESC;

-- Identify Suppliers with Good Delivery and Quality Performance
SELECT
    s.SupplierID,
    s.SupplierName,
    ROUND(
        SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.DeliveryID), 2
    ) AS On_Time_Delivery_Percentage,
    ROUND(
        SUM(q.Accepted_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Quality_Acceptance_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
HAVING
    On_Time_Delivery_Percentage >= 35
    AND Quality_Acceptance_Percentage >= 96
ORDER BY
    On_Time_Delivery_Percentage DESC,
    Quality_Acceptance_Percentage DESC;
    
-- Identify Suppliers with Poor Delivery and Quality Performance
SELECT
    s.SupplierID,
    s.SupplierName,
    ROUND(
        SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.DeliveryID), 2
    ) AS On_Time_Delivery_Percentage,
    ROUND(
        SUM(q.Accepted_Quantity) * 100.0 /
        NULLIF(SUM(q.Inspected_Quantity), 0), 2
    ) AS Quality_Acceptance_Percentage
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
JOIN deliveries d
    ON p.PO_ID = d.PO_ID
JOIN quality_inspection q
    ON p.PO_ID = q.PO_ID
GROUP BY
    s.SupplierID,
    s.SupplierName
HAVING
    On_Time_Delivery_Percentage < 30
    AND Quality_Acceptance_Percentage < 96
ORDER BY
    On_Time_Delivery_Percentage ASC;
    

-- Identify Suppliers with High Procurement Spend but Poor Delivery Performance
WITH Supplier_Performance AS (
    SELECT
        s.SupplierID,
        s.SupplierName,
        SUM(p.Total_Amount_INR) AS Total_Procurement_Spend,
        ROUND(
            SUM(CASE WHEN d.Delivery_Status = 'On Time' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(d.DeliveryID), 2
        ) AS On_Time_Delivery_Percentage
    FROM suppliers s
    JOIN purchase_orders p
        ON s.SupplierID = p.SupplierID
    JOIN deliveries d
        ON p.PO_ID = d.PO_ID
    GROUP BY
        s.SupplierID,
        s.SupplierName
)
SELECT *
FROM Supplier_Performance
WHERE On_Time_Delivery_Percentage < 35
ORDER BY Total_Procurement_Spend DESC;

-- Rank Suppliers by Procurement Spend Within Each Region
SELECT
    s.SupplierRegion,
    s.SupplierID,
    s.SupplierName,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend,
    RANK() OVER (
        PARTITION BY s.SupplierRegion
        ORDER BY SUM(p.Total_Amount_INR) DESC
    ) AS Regional_Supplier_Rank
FROM suppliers s
JOIN purchase_orders p
    ON s.SupplierID = p.SupplierID
GROUP BY
    s.SupplierRegion,
    s.SupplierID,
    s.SupplierName
ORDER BY
    s.SupplierRegion,
    Regional_Supplier_Rank;
    
-- Rank Materials by Procurement Spend Within Each Category
SELECT
    m.MaterialCategory,
    m.MaterialID,
    m.MaterialName,
    SUM(p.Total_Amount_INR) AS Total_Procurement_Spend,
    RANK() OVER (
        PARTITION BY m.MaterialCategory
        ORDER BY SUM(p.Total_Amount_INR) DESC
    ) AS Material_Rank
FROM materials m
JOIN purchase_orders p
    ON m.MaterialID = p.MaterialID
GROUP BY
    m.MaterialCategory,
    m.MaterialID,
    m.MaterialName
ORDER BY
    m.MaterialCategory,
    Material_Rank;
    
-- Identify Potential Duplicate Purchase Orders
SELECT
    SupplierID,
    MaterialID,
    PO_Date,
    Order_Quantity,
    Unit_Price_INR,
    COUNT(*) AS Duplicate_Count
FROM purchase_orders
GROUP BY
    SupplierID,
    MaterialID,
    PO_Date,
    Order_Quantity,
    Unit_Price_INR
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;

-- Identify Unpaid Purchase Orders
SELECT
    PO_ID,
    SupplierID,
    PO_Date,
    Total_Amount_INR,
    Payment_Status
FROM purchase_orders
WHERE Payment_Status = 'Pending'
ORDER BY Total_Amount_INR DESC;

-- Identify High-Value Purchase Orders
SELECT
    PO_ID,
    SupplierID,
    PO_Date,
    Total_Amount_INR,
    Payment_Status
FROM purchase_orders
WHERE Total_Amount_INR > (
    SELECT AVG(Total_Amount_INR)
    FROM purchase_orders
)
ORDER BY Total_Amount_INR DESC
LIMIT 20;

-- Generate Overall Procurement Performance Summary
SELECT
    COUNT(PO_ID) AS Total_Purchase_Orders,
    COUNT(DISTINCT SupplierID) AS Total_Suppliers,
    ROUND(SUM(Total_Amount_INR), 2) AS Total_Procurement_Spend_INR,
    ROUND(AVG(Total_Amount_INR), 2) AS Average_PO_Value_INR,
    SUM(Order_Quantity) AS Total_Quantity_Ordered,
    SUM(CASE WHEN Payment_Status = 'Paid' THEN 1 ELSE 0 END) AS Paid_Orders,
    SUM(CASE WHEN Payment_Status = 'Pending' THEN 1 ELSE 0 END) AS Pending_Orders,
    SUM(CASE WHEN Payment_Status = 'Partially Paid' THEN 1 ELSE 0 END) AS Partially_Paid_Orders
FROM purchase_orders;