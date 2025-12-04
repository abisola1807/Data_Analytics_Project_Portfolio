select * from afri_tech_data


CREATE TABLE CustomerData(
    Customerid INT PRIMARY KEY,
    Customername TEXT,
    Region TEXT,
    Age INT,
    Income NUMERIC,
    Customertype TEXT
);

CREATE TABLE TransactionData(
Transactionid SERIAL PRIMARY KEY,
Customerid INT,
TransactionYear INT,
Transactiondate DATE,
ProductPurchased TEXT,
Purchaseamount NUMERIC,
Productrecalled BOOLEAN,
FOREIGN KEY (Customerid) REFERENCES CustomerData)

DROP TABLE IF EXISTS SocialMedia;  -- Safe drop

CREATE TABLE SocialMedia (
    Postid SERIAL PRIMARY KEY,
    Customerid INT,
    Interactiondate DATE,
    Platform TEXT,
    Posttype TEXT,
    Engagementlikes INT,
    EngagementComments INT,
    UserFollowers INT,
    InfluencerScore NUMERIC(5,3),
    Brandmention BOOLEAN,
    CompetitorMention BOOLEAN,
    Sentiment TEXT,
    Competitor_x TEXT,
    CrisisEventTime DATE,
    FirstResponseTime DATE,  -- Comma added
    Resolutionstatus BOOLEAN,
    Npsresponse INT,
    FOREIGN KEY (Customerid) REFERENCES CustomerData (Customerid)  -- Lowercase consistency
);  -- Semicolon added

INSERT INTO SocialMedia (
    customerid,
    interactiondate,
    platform,
    posttype,
    engagementlikes,
    engagementcomments,
    userfollowers,
    influencerscore,
    brandmention,
    competitormention,
    sentiment,
    competitor_x,
    crisiseventtime,
    firstresponsetime,
    resolutionstatus,
    npsresponse
)
SELECT 
    customerid,
    interactiondate,
    platform,
    posttype,
    engagementlikes,
    engagementcomments,
    userfollowers,
    influencerscore,
    brandmention,
    competitormention,
    sentiment,
    competitor,  -- Maps to competitor_x
    crisiseventtime,
    firstresponsetime,
    resolutionstatus,
    npsresponse
FROM afri_tech_data
WHERE interactiondate IS NOT NULL  -- Filters valid posts
ON CONFLICT (postid) DO NOTHING;  -- Skips duplicates


SELECT * FROM CustomerData

SELECT * FROM TransactionData

SELECT * FROM SocialMedia

INSERT INTO Customerdata(Customerid,Customername,Region,Age,Income,Customertype)
SELECT DISTINCT Customerid,Customername,Region,Age,Income,Customertype
FROM afri_tech_data 

INSERT INTO TransactionData(
Customerid,
TransactionYear,
Transactiondate,
ProductPurchased,
Purchaseamount,
Productrecalled
)

SELECT DISTINCT Customerid,
TransactionYear,
Transactiondate,
ProductPurchased,
Purchaseamount,
Productrecalled
FROM afri_tech_data 

INSERT INTO SocialMedia(Postid SERIAL PRIMARY KEY,
Customerid, 
Interactiondate,
Platform,
Posttype,
Engagementlikes, 
Engagementshares,
EngagementComments,
UserFollowers,
InfluencerScore,
Brandmention,
CompetitorMention,
Sentiment,
Competitor_x,
CrisisEventTime,
FirstResponseTime,
Resolutionstatus,
Npsresponse
)





--

SELECT * FROM CustomerData

SELECT * FROM TransactionData


SELECT * FROM SocialMedia


--Data cleaning
--Replace the Year column
UPDATE TransactionData
SET transactionyear = EXTRACT('YEAR' FROM transactiondate)
WHERE transactionyear <> EXTRACT('YEAR' FROM transactiondate);


-- Replace the post that did not mention competitors
UPDATE SocialMedia
SET competitor_x = 'None'
WHERE competitor_x IS NULL OR competitor_x = ''

SELECT *
FROM SocialMedia
WHERE competitor_x = 'None'

-- Exploratory Data Analysis (Customer data)
--How many Customers are in each region

SELECT region, Count(*) AS Regioncount
FROM Customerdata
GROUP BY region
ORDER BY Regioncount DESC

--How many Unique Customers do we have?
SELECT Count(Distinct CustomerId) AS Uniquecustomers
From Customerdata

--What is the highest, lowest and average age of the customers

SELECT MAX(Age) AS Highest_age,
MIN(Age) AS Lowest_age,
ROUND(AVG(Age), 0) AS Average_age
FROM CustomerData

-- What is the Customer distribution like?
SELECT customertype, Count(*) AS type_count
FROM Customerdata
GROUP BY customertype
ORDER BY TYPE_COUNT DESC

-- 
-- What is the income distribution of customers
SELECT ROUND(MAX(Income),2) AS Highest_income,
ROUND(MIN(Income),2) AS Lowest_income,
ROUND(AVG(Income),2) AS Average_income
FROM Customerdata


-- What is the product price distribution like?
SELECT ROUND(MAX(PurchaseAmount),2) AS Highest_price,
ROUND(MIN(PurchaseAmount),2) AS Lowest_Price, 
ROUND(AVG(PurchaseAmount),2) AS Average_price
FROM TransactionData

-- What is the product purchase distribution and the purchase amount
SELECT ProductPurchased, COUNT(*) AS Purchase_Quantity, SUM(Purchaseamount) AS Total_sales
FROM TransactionData
GROUP BY ProductPurchased
ORDER BY Total_sales DESC

-- what are the product recalled behaviour
SELECT Productrecalled, COUNT(*) AS PurchaseQuality, SUM(PurchaseAmount) AS Total_sales
FROM TransactionData
GROUP BY Productrecalled
ORDER BY Total_sales DESC


--Social media
-- What are the likes behaviour per platform
SELECT Platform, SUM(Engagementlikes) AS Total_likes, AVG(Engagementlikes) AS Average_likes
FROM SocialMedia
GROUP BY Platform
ORDER BY Total_likes DESC-- Tiktok has the highest and average likes

-- which post type gets the most engagement?
SELECT 
    posttype AS PostType,
    round(AVG(engagementlikes + engagementcomments), 2) AS Avg_engagement,
    round(AVG(influencerscore), 2) AS AVGInfluencerScore
FROM SocialMedia
GROUP BY posttype
ORDER BY Avg_engagement DESC;--video posts has the highest avg_engagement and story posts with the highest influencer score


-- CUSTOMER DATA INSIGHTS
--1. What are the TOP 5 regions with the highest average income (Sola)

SELECT Region,
 CONCAT('$', ROUND(AVG(Income), 2)) AS AverageIncome
FROM Customerdata
GROUP BY Region
ORDER BY AVG(Income) DESC
LIMIT 5;

-- 2.Number of complaints by customertype
select customertype, count(crisiseventtime) as "Number of complaints"
from socialmedia
left join customerdata
using (customerid)
group by 1
order by 2 desc; 

--3. Who are the top spending customers?
SELECT cd.CustomerID, SUM(PurchaseAmount) AS TotalSpend, COUNT(*) AS NumTransactions
FROM customerdata as cd 
left join transactiondata as dt
on cd.customerid = dt.customerid
GROUP BY cd.CustomerID
ORDER BY TotalSpend DESC;

--4. Total amount spent & Number of complaints by demography

WITH complaint_counts AS (
  SELECT customerid, COUNT(*) AS complaint_count
  FROM socialmedia
  WHERE crisiseventtime IS NOT NULL
  GROUP BY customerid
)
SELECT 
  CASE 
    WHEN age < 31 THEN 'Young'
    WHEN age >= 31 AND age < 50 THEN 'Adult'
    WHEN age >= 50 THEN 'Old'
  END AS age_category,
  SUM(purchaseamount) AS "Total Money spent",
  SUM(COALESCE(complaint_count, 0)) AS "Number of complaints"
FROM transactiondata
LEFT JOIN customerdata USING (customerid)
LEFT JOIN complaint_counts USING (customerid)
GROUP BY age_category
ORDER BY age_category DESC;

--5. Business Challenge 1 and 3
SELECT  
  platform, 

  -- Total posts by sentiment
  COUNT(*) FILTER (WHERE sm.Sentiment = 'Negative') AS negative_mentions,
  COUNT(*) FILTER (WHERE t.ProductRecalled = TRUE AND sm.Sentiment = 'Negative') AS recalls_negative,

  COUNT(*) FILTER (WHERE sm.Sentiment = 'Positive') AS positive_mentions,
  COUNT(*) FILTER (WHERE t.ProductRecalled = TRUE AND sm.Sentiment = 'Positive') AS recalls_positive,

  COUNT(*) FILTER (WHERE sm.Sentiment = 'Neutral') AS neutral_mentions,
  COUNT(*) FILTER (WHERE t.ProductRecalled = TRUE AND sm.Sentiment = 'Neutral') AS recalls_neutral,

   -- Total recalls (across all sentiments)
  COUNT(*) FILTER (WHERE t.ProductRecalled = TRUE) AS total_recalls

FROM Socialmedia AS sm
JOIN TransactionData AS t ON sm.Customerid = t.Customerid

GROUP BY platform
ORDER BY total_recalls DESC


-- TRANSACTION DATA INSIGHTS

--6. What is the revenue trend by year?

SELECT customertype, 
 	sum(purchaseamount) as "Total spendings", count(crisiseventtime) as "Number of complaints"
from transactiondata  
left join customerdata  
using(customerid)
left join socialmedia
using(customerid)
group by 1
order by 2 desc;

--7. products with the highest number of recall
select count(productpurchased) as "Number of items", productpurchased
from TransactionData
group by 2,productrecalled
having productrecalled ='true'
order by 1 desc

--8. Products Recall by Sentiments

SELECT  platform,
 COUNT(*) FILTER (WHERE sm.Sentiment = 'Negative') AS negative_mentions,
 COUNT(*) FILTER (WHERE sm.Sentiment = 'Positive') AS Positive_mentions,
 COUNT(*) FILTER (WHERE sm.Sentiment = 'Neutral') AS Neutral_mentions,
COUNT(*) FILTER (WHERE t.ProductRecalled = TRUE) AS recalls
FROM  Socialmedia AS sm
JOIN     TransactionData T 
ON SM.Customerid = T.Customerid
GROUP BY  platform
ORDER BY recalls DESC

--9. Top  revenue generating products? 
SELECT productpurchased, SUM(purchaseamount) AS total_revenue
FROM transactiondata
GROUP BY productpurchased
ORDER BY total_revenue DESC

-- RECALLED RATE
SELECT
  date_trunc('month', transactiondate)::date AS month,
  COUNT(*) FILTER (WHERE productrecalled) AS recalled_orders,
  ROUND(100.0 * COUNT(*) FILTER (WHERE productrecalled) / COUNT(*), 2) AS recall_rate_pct
FROM transactiondata
GROUP BY month
ORDER BY month;


--     SOCIAL MEDIA INSIGHTS

-- 10 How many unresolved crises remain per platform?

SELECT Platform, COUNT(*) AS UnresolvedCount 
FROM SocialMedia 
WHERE ResolutionStatus='False' 
GROUP BY Platform 
ORDER BY UnresolvedCount DESC

--11. Which platforms have the highest concentration of negative posts (Gloria)

SELECT Platform, COUNT(*) AS negative_posts_Cnt
FROM Socialmedia
WHERE Sentiment = 'Negative'
GROUP BY Platform
ORDER BY negative_posts_Cnt DESC

--12. Which competitor’s presence most affects purchase behavior?

SELECT Competitor_x, COUNT(*) AS Transactions 
FROM SocialMedia 
WHERE Competitor_x IS NOT NULL
GROUP BY Competitor_x 
ORDER BY Transactions DESC

-- 13. Negative trend over time
SELECT
  date_trunc('month', interactiondate)::date AS month,
  COUNT(*) FILTER (WHERE LOWER(sentiment) = 'negative') AS negative_posts
FROM socialmedia
GROUP BY month
ORDER BY month;

-- 14. Interval(Days) between crisiseventtime and firstresponsetime

SELECT 	platform,
ROUND(AVG(EXTRACT(DAY FROM(firstresponsetime::timestamp - crisiseventtime::timestamp))),0) || 'Days' AS average_response_time_days
FROM socialmedia
WHERE firstresponsetime IS NOT NULL
GROUP BY platform
ORDER BY average_response_time_days DESC;





