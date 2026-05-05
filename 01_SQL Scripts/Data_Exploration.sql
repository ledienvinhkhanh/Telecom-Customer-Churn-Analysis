USE churn_project;
SELECT * FROM customer_churn LIMIT 10;

-- --------------------------------------------------------------------------
-- Query 1: Aggregate Churn Rate by Internet Service and Contract
-- --------------------------------------------------------------------------
SELECT 
    Contract,
    InternetService,
    COUNT(customerID) AS Total_Customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND((SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(customerID)) * 100, 2) AS Churn_Rate_Pct
FROM 
    customer_churn
GROUP BY 
    Contract, 
    InternetService
ORDER BY 
    Churn_Rate_Pct DESC;
    
-- --------------------------------------------------------------------------
-- Query 2: Analyze Technical Support Call Behavior with Churn Rate (using CTE)
-- --------------------------------------------------------------------------
WITH Ticket_Categories AS (
    SELECT 
        customerID,
        numTechTickets,
        Churn,
        CASE 
            WHEN numTechTickets = 0 THEN '0 Tickets'
            WHEN numTechTickets BETWEEN 1 AND 2 THEN '1-2 Tickets'
            WHEN numTechTickets BETWEEN 3 AND 5 THEN '3-5 Tickets'
            ELSE '6+ Tickets'
        END AS Tech_Ticket_Volume
    FROM customer_churn
)
SELECT 
    Tech_Ticket_Volume,
    COUNT(customerID) AS Total_Customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND((SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(customerID)) * 100, 2) AS Churn_Rate_Pct
FROM 
    Ticket_Categories
GROUP BY 
    Tech_Ticket_Volume
ORDER BY 
    Churn_Rate_Pct DESC;
    
-- -----------------------------------------------------------------------------------------------------------
-- Query 3: Identify Top 50 High-Value (VIP) Customers Who Have Churned (Using Window Functions)
-- -----------------------------------------------------------------------------------------------------------
WITH Ranked_Lost_Customers AS (
    SELECT 
        customerID,
        tenure,
        Contract,
        MonthlyCharges,
       
        CAST(NULLIF(TRIM(TotalCharges), '') AS DECIMAL(10,2)) AS TotalCharges_Clean,
        RANK() OVER(
            ORDER BY CAST(NULLIF(TRIM(TotalCharges), '') AS DECIMAL(10,2)) DESC
        ) AS Revenue_Rank
    FROM 
        customer_churn
    WHERE 
        Churn = 'Yes'
)
SELECT * FROM 
    Ranked_Lost_Customers 
WHERE 
    Revenue_Rank <= 50;
    
-- --------------------------------------------------------------------------
-- Query 4: Identify High-Risk Customer Profiles (Advanced Filtering)
-- --------------------------------------------------------------------------
SELECT 
    customerID,
    tenure,
    InternetService,
    MonthlyCharges,
    numTechTickets
FROM 
    customer_churn
WHERE 
    Churn = 'No' -- Khách hàng vẫn đang dùng
    AND Contract = 'Month-to-month' -- Hợp đồng tháng
    AND InternetService = 'Fiber optic' -- Dùng cáp quang
    AND numTechTickets >= 3 -- Đã gọi hỗ trợ kỹ thuật trên 3 lần
ORDER BY 
    MonthlyCharges DESC;