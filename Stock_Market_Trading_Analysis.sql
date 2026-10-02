CREATE DATABASE stockmarketDB;

USE stockmarketDB;

CREATE TABLE tradingdata
(
Trade_ID VARCHAR(10) PRIMARY KEY,
    Trade_Date DATE,
    Trader_Name VARCHAR(50),
    Stock_Symbol VARCHAR(20),
    Company_Name VARCHAR(100),
    Sector VARCHAR(50),
    Trade_Type VARCHAR(10),
    Quantity INT,
    Buy_Price DECIMAL(10,2),
    Sell_Price DECIMAL(10,2),
    Brokerage DECIMAL(10,2),
    Trade_Status VARCHAR(20),
    Gross_Value DECIMAL(15,2),
    Profit_Loss DECIMAL(15,2),
    Return_Percentage DECIMAL(10,2)
);

DESCRIBE tradingdata;

SELECT COUNT(*) AS trading_data1
FROM tradingdata;

SELECT*FROM tradingdata
LIMIT 10;

SELECT*FROM tradingdata
ORDER BY Trade_ID;

#Data Validation
#Check duplicate Trade IDs

SELECT Trade_ID, COUNT(*) AS count
FROM tradingdata
GROUP BY Trade_ID
HAVING COUNT >= 1;

#Check missing values

SELECT*FROM tradingdata
WHERE Trade_ID IS NULL
OR Trade_Date IS NULL
OR Trader_Name IS NULL
OR Stock_Symbol IS NULL
OR Company_Name IS NULL
OR Sector IS NULL
OR Brokerage IS NULL
OR Trade_Status IS NULL;

#calculation validation

SELECT
Trade_ID,
Trader_Name,
Quantity,
Buy_Price,
Gross_Value,
Quantity*Buy_Price AS Gross
FROM tradingdata
WHERE Gross_Value<>Quantity*Buy_Price;

#Check Profit/Loss

SELECT
Trade_ID,
Profit_Loss,
((Sell_Price-Buy_Price)*Quantity-Brokerage) AS calculated_profit_loss
FROM tradingdata
WHERE Profit_Loss<>((Sell_Price-Buy_Price)*Quantity-Brokerage);

#Detailed mismatch check
SELECT
    Trade_ID,
    Quantity,
    Buy_Price,
    Sell_Price,
    Brokerage,
    Gross_Value,
    Profit_Loss,
    (Sell_Price - Buy_Price) * Quantity AS Price_Difference,
    ((Sell_Price - Buy_Price) * Quantity) - Brokerage AS Calculated_Profit_Loss
FROM tradingdata
WHERE Profit_Loss <>
      ((Sell_Price - Buy_Price) * Quantity - Brokerage);
      
#Checking the four specific records
SELECT
    Trade_ID,
    Quantity,
    Buy_Price,
    Sell_Price,
    Brokerage,
    Profit_Loss,
    (Sell_Price - Buy_Price) * Quantity AS Price_Profit,
    ((Sell_Price - Buy_Price) * Quantity) - Brokerage AS Calculated_Profit_Loss
FROM tradingdata
WHERE Trade_ID IN ('T0024', 'T0028', 'T0048', 'T0071');

#Showing the exact difference
SELECT
    Trade_ID,
    Quantity,
    Buy_Price,
    Sell_Price,
    Brokerage,
    Profit_Loss,
    (Sell_Price - Buy_Price) * Quantity AS Price_Profit,
    ((Sell_Price - Buy_Price) * Quantity) - Brokerage AS Calculated_Profit_Loss,
    Profit_Loss - (((Sell_Price - Buy_Price) * Quantity) - Brokerage) AS Difference
FROM tradingdata
WHERE Trade_ID IN ('T0024', 'T0028', 'T0048', 'T0071');

#Creating the validation view
CREATE VIEW tradingdata_validated AS
SELECT
    *,
    ROUND(
        ((Sell_Price - Buy_Price) * Quantity) - Brokerage,
        2
    ) AS Calculated_Profit_Loss,
    ROUND(
        Profit_Loss -
        (((Sell_Price - Buy_Price) * Quantity) - Brokerage),
        2
    ) AS Profit_Loss_Difference
FROM tradingdata;

#Checking the validation view
SELECT
    Trade_ID,
    Profit_Loss,
    Calculated_Profit_Loss,
    Profit_Loss_Difference
FROM tradingdata_validated
WHERE Profit_Loss_Difference <> 0;

#Trader Performance Analysis

SELECT 
Trader_Name,
COUNT(*) AS total_trades,
SUM(Quantity) AS total_quantity,
ROUND(SUM(Gross_Value)) AS total_gross,
ROUND(SUM(Profit_Loss)) AS total_profit_loss,
ROUND(AVG(Return_Percentage)) AS total_percentage
FROM tradingdata
GROUP BY Trader_Name
ORDER BY total_profit_loss DESC;

#Stock Performance Analysis

SELECT
Stock_Symbol,
Company_Name,
Sector,
COUNT(*) AS total_trades,
SUM(Quantity) AS total_quantity,
ROUND(SUM(Gross_Value)) AS total_gross,
ROUND(SUM(Profit_Loss)) AS total_profit_loss,
ROUND(AVG(Return_Percentage)) AS total_percentage
FROM tradingdata
GROUP BY 
Stock_Symbol,
Company_Name,
Sector
ORDER BY total_profit_loss DESC;

#Sector Performance

SELECT
    Sector,
    COUNT(*) AS Total_Trades,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(Gross_Value), 2) AS Total_Trade_Value,
    ROUND(SUM(Profit_Loss), 2) AS Total_Profit_Loss,
    ROUND(AVG(Return_Percentage), 2) AS Average_Return_Percentage
FROM tradingdata
GROUP BY Sector
ORDER BY Total_Profit_Loss DESC;

#Monthly Trading Analysis

SELECT
DATE_FORMAT(Trade_date,'%Y-%m') AS Trading_month,
COUNT(*) AS Total_Trades,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(Gross_Value), 2) AS Total_Trade_Value,
    ROUND(SUM(Profit_Loss), 2) AS Total_Profit_Loss,
    ROUND(AVG(Return_Percentage), 2) AS Average_Return_Percentage
FROM tradingdata
GROUP BY DATE_FORMAT(Trade_Date, '%Y-%m')
ORDER BY Trading_month;

#Profit vs Loss Analysis

SELECT
CASE
WHEN Profit_Loss > 0 THEN 'profit'
WHEN Profit_Loss < 0 THEN 'loss'
ELSE 'no_profit/no_loss'
END AS trade_result,
COUNT(*) AS total_trades,
ROUND(SUM(Profit_Loss),2) AS total_profit,
ROUND(AVG(Profit_Loss),2) AS AVG_total_profit
FROM tradingdata
GROUP BY trade_result
ORDER BY total_profit;

#Top 10 Most Profitable Trades

SELECT
    Trade_ID,
    Trade_Date,
    Trader_Name,
    Stock_Symbol,
    Company_Name,
    Sector,
    Quantity,
    Buy_Price,
    Sell_Price,
    Brokerage,
    Profit_Loss,
    Return_Percentage
FROM tradingdata
ORDER BY Profit_Loss DESC
LIMIT 10;

#Worst-Performing Trades

SELECT
    Trade_ID,
    Trade_Date,
    Trader_Name,
    Stock_Symbol,
    Company_Name,
    Sector,
    Quantity,
    Buy_Price,
    Sell_Price,
    Brokerage,
    Profit_Loss,
    Return_Percentage
FROM tradingdata
ORDER BY Profit_Loss ASC
LIMIT 10;

#Which traders generated more than ₹30,000 total Profit/Loss? 
#USING CTE

WITH trader_performance AS(
SELECT
Trader_Name,
COUNT(*) AS total_trades,
SUM(Profit_Loss) AS total_p_L,
AVG(Return_Percentage) AS avg_return
FROM tradingdata
GROUP BY Trader_Name
)
SELECT
Trader_Name,
total_trades,
ROUND(total_p_L,2) AS total_p_L,
ROUND(avg_return,2) AS avg_return
FROM trader_performance
WHERE total_p_L > 30000
ORDER BY total_p_L DESC; 

#How do traders rank based on their total Profit/Loss?
#using Window Functions

WITH trader_performance AS(
SELECT
Trader_Name,
SUM(Profit_Loss) AS total_profit_loss
FROM tradingdata
GROUP BY Trader_Name
)
SELECT
Trader_Name,
ROUND(total_profit_loss,2) AS total_P_L,
RANK()OVER(ORDER BY total_profit_loss DESC) AS profit_rank
FROM trader_performance
ORDER BY profit_rank;

#Can we assign a unique number to each trader based on their total Profit/Loss?

WITH trader_performance AS(
SELECT
Trader_Name,
SUM(Profit_Loss) AS total_profit_loss
FROM tradingdata
GROUP BY Trader_Name
)
SELECT
Trader_Name,
ROUND(total_profit_loss,2) AS total_p_L,
ROW_NUMBER() OVER(ORDER BY total_profit_loss DESC) AS total_p_L
FROM trader_performance
ORDER BY total_p_L;

#PARTITION BY + Window Functions
#trader's total P/L for each sector by comparing within that sector

SELECT
Sector,
Trader_Name,
ROUND(SUM(Profit_Loss),2) AS trader_sector_profit_loss,
ROUND(SUM(SUM(Profit_Loss)) OVER(PARTITION BY Sector),2) AS total_sector_profit_loss
FROM tradingdata
GROUP BY Sector,Trader_Name
ORDER BY Sector,trader_sector_profit_loss;

#Final SQL View

CREATE OR REPLACE VIEW trading_analysis AS
SELECT
    Trade_ID,
    Trade_Date,
    Trader_Name,
    Stock_Symbol,
    Company_Name,
    Sector,
    Trade_Type,
    Quantity,
    Buy_Price,
    Sell_Price,
    Brokerage,
    Trade_Status,
    Gross_Value,
    Profit_Loss,
    Return_Percentage,

    ROUND(
        ((Sell_Price - Buy_Price) * Quantity) - Brokerage,
        2
    ) AS Calculated_Profit_Loss,

    ROUND(
        Profit_Loss -
        (((Sell_Price - Buy_Price) * Quantity) - Brokerage),
        2
    ) AS Profit_Loss_Difference,

    CASE
        WHEN Profit_Loss > 0 THEN 'Profit'
        WHEN Profit_Loss < 0 THEN 'Loss'
        ELSE 'No Profit / No Loss'
    END AS Trade_Result

FROM tradingdata;

SELECT * FROM trading_analysis
LIMIT 10;

SELECT COUNT(*) AS Total_Records
FROM trading_analysis;














