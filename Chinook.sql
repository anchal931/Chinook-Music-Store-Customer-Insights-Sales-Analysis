-- Objective Questions
-- 1. Does any table have missing values or duplicates? If yes how would you handle it?
-- a.track table
select * from track;
update track set composer='Unknown' where composer is null;

-- b. customer table getting count for null values for each column
SELECT 'First_Name' AS ColumnName, COUNT(*) AS NullCount FROM customer WHERE First_Name IS NULL
UNION ALL
SELECT 'customer_id' AS ColumnName, COUNT(*) FROM customer WHERE customer_id IS NULL
UNION ALL
SELECT 'Last_Name', COUNT(*) FROM customer WHERE Last_Name IS NULL
UNION ALL
SELECT 'company', COUNT(*) FROM customer WHERE company IS NULL
UNION ALL
SELECT 'Address', COUNT(*) FROM customer WHERE Address IS NULL
UNION ALL
SELECT 'City', COUNT(*) FROM customer WHERE City IS NULL
UNION ALL
SELECT 'State', COUNT(*) FROM customer WHERE State IS NULL
UNION ALL
SELECT 'Country', COUNT(*) FROM customer WHERE Country IS NULL
UNION ALL
SELECT 'Postal_Code', COUNT(*) FROM customer WHERE Postal_Code IS NULL
UNION ALL
SELECT 'Phone', COUNT(*) FROM customer WHERE Phone IS NULL
UNION ALL
SELECT 'Fax', COUNT(*) FROM customer WHERE Fax IS NULL
UNION ALL
SELECT 'Email', COUNT(*) FROM customer WHERE Email IS NULL
ORDER BY NullCount DESC;
SET SQL_SAFE_UPDATES = 0;

alter table customer drop column company;
alter table customer drop column fax;
UPDATE customer 
SET 
    State = COALESCE(State, 'Unknown'), 
    Postal_Code = COALESCE(Postal_Code, '00000'),
    Phone = COALESCE(Phone, 'Not Provided');

select * from customer;

-- 2. Find the top-selling tracks and top artist in the USA and identify their most famous genres.
with top_selling_track as(
select track_id, total_price from
(select 
	track_id, sum(unit_price*quantity) as total_price,
	dense_rank() over (order by sum(unit_price*quantity) desc) as rnk
from 
	invoice i 
join 
	invoice_line il
on 
	i.invoice_id = il.invoice_id
where billing_country='USA'
group by 1) a where rnk=1)

select 
	t.name as track_name, g.name as genre_name, ar.name as artist_name, c.total_price
from 
	track t 
join genre g on t.genre_id=g.genre_id
join album a on a.album_id=t.album_id
join artist ar on ar.artist_id=a.artist_id
join top_selling_track c on c.track_id=t.track_id;

-- 3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
SELECT Country, COUNT(*) AS Customer_Count
FROM Customer
GROUP BY Country
ORDER BY 2 DESC;

-- 4. Calculate the total revenue and number of invoices for each country, state, and city:

select 
	i.billing_country as country,
    i.billing_state as state, 
    i.billing_city as city, 
    count(i.invoice_id) as invoice_count,
    sum(unit_price*quantity) as revenue
from 
	invoice i 
join 
	invoice_line il 
on 
	i.invoice_id=il.invoice_id
where billing_state<>'None'
group by 
	country,state,city
order by 
	country,state,city;

-- 5. Find the top 5 customers by total revenue in each country.
with cte as(
select 
	c.country,c.customer_id,
    concat(c.first_name,' ', c.last_name) as customer_name,
	sum(il.unit_price*il.quantity) as revenue,
    dense_rank() over (partition by c.country order by sum(il.unit_price*il.quantity) desc) as rnk
from 
	customer c 
join 
	invoice i 
on c.customer_id=i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
group by 1,2,3)

select 
	country, 
    customer_name, 
    revenue 
from 
	cte 
where rnk<6
order by country, rnk; 

-- 6. Identify the top-selling track for each customer
with sales_track as(
select 
	c.customer_id,concat (c.first_name,' ', c.last_name) as customer_name,
    t.track_id, t.name as track_tname, count(il.track_id) as purchase_count,
    RANK() OVER (PARTITION BY c.Customer_ID ORDER BY COUNT(il.Track_ID) DESC, t.track_id ASC) AS rnk
from 
	customer c 
join invoice i on c.customer_id=i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on il.track_id=t.track_id
group by 1,2,3,4)

select customer_id, customer_name, track_id, track_tname, purchase_count from sales_track 
where rnk=1
order by customer_id ;


-- 7. Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?
select 
	customer_id,
	avg(unit_price*quantity) as avg_order_value,
    sum(unit_price*quantity) as sum_order_value
from 
	invoice i 
join invoice_line il on i.invoice_id=il.invoice_id
group by 1
order by 2 desc;

WITH PurchaseDifferences AS (
    SELECT 
        customer_id, 
        invoice_id, 
        invoice_date, 
        TIMESTAMPDIFF(DAY, 
            LAG(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date), 
            invoice_date
        ) AS days_between_purchases
    FROM invoice
)
SELECT 
    customer_id, 
    COUNT(invoice_id) AS total_purchases,
    ROUND(AVG(days_between_purchases), 2) AS avg_days_between_purchases
FROM PurchaseDifferences
WHERE days_between_purchases IS NOT NULL
GROUP BY customer_id
ORDER BY total_purchases DESC;

-- 8. What is the customer churn rate?
with cte as (
select year(invoice_date) as Year , count(DISTINCT customer_id) as CustomersAtStart 
from invoice
group by 1)

select 
	Year, 
    CustomersAtStart, 
    lead(CustomersAtStart) over (order by Year) as CustomersAtEnd,
    round(((CustomersAtStart- lead(CustomersAtStart) over (order by Year))/CustomersAtStart)*100,2) as churn_rate
from cte;

-- 9. Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
-- part 1: the percentage of total sales contributed by each genre in the USA
with cte as(
select g.name as genre_name, sum(il.unit_price*quantity) as sales
from genre g join track t on g.genre_id=t.genre_id
join invoice_line iL on il.track_id=t.track_id
join invoice i on i.invoice_id = il.invoice_id
where billing_country = 'USA'
group by g.name)
, totl_sale_amount as(
select sum(sales) total_sales from cte)

select genre_name, round((sales/total_sales)*100,2) as percentage_sales 
from cte, totl_sale_amount
order by 2 desc;

-- part 2: the best-selling genres and artists worldwide.
-- (a) best-selling genres
with genre_ranking as(
select
	g.name as genre_name, 
    sum(il.unit_price*quantity) as sales,
	dense_rank() over (order by sum(il.unit_price*quantity) desc) as rnk
from genre g join track t on g.genre_id=t.genre_id
join invoice_line iL on il.track_id=t.track_id
join invoice i on i.invoice_id = il.invoice_id
group by g.name)

select * from genre_ranking where rnk=1;

-- b. top artists 
with artist_ranking as(
select 
	ar.artist_id, 
    ar.name as artist_name, 
    sum(il.unit_price*quantity) as sales,
	dense_rank() over (order by sum(il.unit_price*quantity) desc) as rnk
from invoice_line il 
join track t on il.track_id=t.track_id
join album a on a.album_id=t.album_id
join artist ar on ar.artist_id=a.artist_id
group by 1,2)

select * from artist_ranking where rnk=1;

-- 10. Find customers who have purchased tracks from at least 3 different genres.

select 
	c.customer_id, 
    concat(first_name,' ', last_name) as customer_name, 
    count(distinct g.genre_id) as genre_count
from 
	customer c 
join invoice i on i.customer_id=c.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id
group by 1,2
having count(distinct g.genre_id)>=3
order by genre_count desc;

-- 11. Rank genres based on their sales performance in the USA.
select
	g.name as genre_name, 
    sum(il.unit_price*quantity) as sales,
	dense_rank() over (order by sum(il.unit_price*quantity) desc) as rnk
from genre g join track t on g.genre_id=t.genre_id
join invoice_line iL on il.track_id=t.track_id
join invoice i on i.invoice_id = il.invoice_id
where i.billing_country = 'USA'
group by g.name;

-- 12. Identify customers who have not made a purchase in the last 3 months.
select 
	customer_id, 
    concat(first_name,' ',last_name) as customer_name 
from 
	customer 
where customer_id 
not in (
	SELECT DISTINCT customer_id
	FROM invoice
	WHERE invoice_date >= DATE_SUB((SELECT MAX(invoice_date) FROM invoice), INTERVAL 3 MONTH)
)
order by customer_id;


-- Subjective Questions 
-- 1. Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.
with genre_analysis as (
select
	g.genre_id,g.name as genre_name, 
    sum(il.unit_price*quantity) as sales
from genre g join track t on g.genre_id=t.genre_id
join invoice_line iL on il.track_id=t.track_id
join invoice i on i.invoice_id = il.invoice_id
where billing_country='USA'
group by g.genre_id,g.name 
order by sales desc
limit 3)
, AlbumSales AS (
    -- Step 2: Identify top-selling albums from the new record label
    SELECT 
        a.album_id,
        a.title AS album_name,
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS total_sales,
        dense_rank() over (order by SUM(il.unit_price * il.quantity) desc) as rnk
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    JOIN genre g ON t.genre_id = g.genre_id
    WHERE i.billing_country = 'USA'
      AND g.genre_id IN (SELECT genre_id FROM genre_analysis)  -- Filter albums in top genres
    GROUP BY a.album_id, a.title, g.name
    ORDER BY total_sales DESC
)
SELECT * FROM AlbumSales where rnk<4;

-- 2. Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
with top_genre_in_country as(
select
	i.billing_country as country,
    g.name as genre_name, 
    sum(il.unit_price*quantity) as sales,
    dense_rank() over (partition by billing_country order by sum(il.unit_price*quantity) desc) as rnk
from genre g join track t on g.genre_id=t.genre_id
join invoice_line iL on il.track_id=t.track_id
join invoice i on i.invoice_id = il.invoice_id
where billing_country <> 'USA'
group by i.billing_country,g.genre_id,g.name )

select 
	country,
    genre_name, 
    sales
from top_genre_in_country
where rnk=1
order by sales desc;

-- 3. Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers? 
-- What insights can these patterns provide about customer loyalty and retention strategies?
with CustomerTenure AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.country,
        MIN(i.invoice_date) AS first_purchase_date, -- First purchase date
        COUNT(DISTINCT i.invoice_id) AS total_purchases, -- Purchase frequency
        SUM(il.unit_price*quantity) AS total_spent, -- Total spending
        ROUND(AVG(il.unit_price*quantity), 2) AS avg_spent_per_purchase, -- Average order value
        ROUND(AVG(track_count), 0) AS avg_tracks_per_invoice, -- Basket size
        CASE 
            WHEN MIN(i.invoice_date) <= DATE_SUB((SELECT MAX(invoice_date) FROM invoice), INTERVAL 3 YEAR) 
            THEN 'Long-Term'
            ELSE 'New'
        END AS customer_type -- Classify customers as Long-Term or New
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN (
        SELECT 
            invoice_id, 
            COUNT(track_id) AS track_count
        FROM invoice_line
        GROUP BY invoice_id
    ) k ON i.invoice_id = k.invoice_id
	join invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id
)
SELECT 
    customer_type,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(total_purchases), 2) AS avg_purchases_per_customer,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(AVG(avg_spent_per_purchase), 2) AS avg_order_value,
    ROUND(AVG(avg_tracks_per_invoice), 0) AS avg_basket_size
FROM CustomerTenure
GROUP BY customer_type;


-- 4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? 
-- How can this information guide product recommendations and cross-selling initiatives?
-- genre
SELECT 
    g1.name AS genre_1, 
    g2.name AS genre_2, 
    COUNT(*) AS purchase_count
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN genre g1 ON t1.genre_id = g1.genre_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id <> il2.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN genre g2 ON t2.genre_id = g2.genre_id
WHERE g1.genre_id < g2.genre_id  -- Avoid duplicate pairs
GROUP BY genre_1, genre_2
ORDER BY purchase_count DESC
LIMIT 10;

-- artist
SELECT 
    a1.name AS artist_1, 
    a2.name AS artist_2, 
    COUNT(*) AS purchase_count
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN artist a1 ON al1.artist_id = a1.artist_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id <> il2.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
JOIN artist a2 ON al2.artist_id = a2.artist_id
WHERE a1.artist_id < a2.artist_id  -- Avoid duplicate pairs
GROUP BY artist_1, artist_2
ORDER BY purchase_count DESC
LIMIT 10;

-- album
SELECT 
    al1.title AS album_1, 
    al2.title AS album_2, 
    COUNT(*) AS purchase_count
FROM invoice_line il1
JOIN track t1 ON il1.track_id = t1.track_id
JOIN album al1 ON t1.album_id = al1.album_id
JOIN invoice_line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id <> il2.track_id
JOIN track t2 ON il2.track_id = t2.track_id
JOIN album al2 ON t2.album_id = al2.album_id
WHERE al1.album_id < al2.album_id  -- Avoid duplicate pairs
GROUP BY album_1, album_2
ORDER BY purchase_count DESC
LIMIT 10;


-- 5. Regional Market Analysis: Do customer purchasing behaviours and churn rates vary across different geographic regions or store locations? 
-- How might these correlate with local demographic or economic factors?

-- purchasing behaviours across different geographic regions
select 
	country,
    count(distinct c.customer_id) as total_customers,
    count(invoice_id) as total_purchases,
    ROUND(COUNT(i.invoice_id) / COUNT(DISTINCT c.customer_id), 2) AS avg_purchases_per_customer
from 
	customer c 
join 
	invoice i on c.customer_id= i.customer_id
group by country
order by avg_purchases_per_customer desc;


-- churn rates across different geographic regions
WITH LatestDate AS (
    SELECT MAX(invoice_date) AS max_invoice_date FROM invoice
),  
CustomerActivity AS (
    SELECT 
        c.customer_id,
        c.country,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country
)
SELECT 
    ca.country,
    COUNT(DISTINCT ca.customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN ca.last_purchase_date <= DATE_SUB((SELECT max_invoice_date FROM LatestDate), INTERVAL 6 MONTH) THEN ca.customer_id END) AS churned_customers,
    ROUND(100 * COUNT(DISTINCT CASE WHEN ca.last_purchase_date <= DATE_SUB((SELECT max_invoice_date FROM LatestDate), INTERVAL 6 MONTH) THEN ca.customer_id END) / COUNT(DISTINCT ca.customer_id), 2) AS churn_rate
FROM CustomerActivity ca
GROUP BY ca.country HAVING churn_rate>0
ORDER BY churn_rate DESC;

-- 6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), 
-- which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?
with Customer_risk_profiling as(
select 
	country, 
    c.customer_id,
    max(invoice_date) as last_purchase_date,
    count(i.invoice_id) as total_purchases,
    sum(quantity*unit_price) as total_spent             
from 
	customer c join invoice i on c.customer_id=i.customer_id
join 
	invoice_line il on il.invoice_id=i.invoice_id
group by c.customer_id, country)

select 
	country,
    count(customer_id) as total_customers,
    round(avg(total_purchases),0) as avg_purchase_count,
    round(avg(total_spent),2) as avg_total_spent,
    count(case when last_purchase_date<= DATE_SUB((select max(invoice_date) from invoice),interval 6 month) then 1 end) as at_risk_customers,
    case 
        when COUNT(CASE WHEN last_purchase_date <= DATE_SUB((SELECT MAX(invoice_date) FROM invoice), INTERVAL 6 MONTH) THEN 1 END) > (COUNT(customer_id) * 0.5) 
        then 'High Risk'
        else 'Low Risk'
    end as risk_category
from 
	Customer_risk_profiling
group by country 
having at_risk_customers <> 0
order by risk_category, at_risk_customers desc;

-- 7. Customer Lifetime Value Modelling: How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer
-- segments? This could inform targeted marketing and loyalty program strategies. 
-- Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
WITH CustomerMetrics AS (
    SELECT 
        c.customer_id,
        c.country,
        MIN(i.invoice_date) AS first_purchase_date,  -- Customer tenure start
        MAX(i.invoice_date) AS last_purchase_date,   -- Last purchase date
        COUNT(i.invoice_id) AS total_purchases,      -- Purchase frequency
        SUM(quantity*unit_price) AS total_spent,                 -- Total revenue from customer
        ROUND(AVG(quantity*unit_price), 2) AS avg_order_value,   -- Average purchase amount
        (SELECT MAX(invoice_date) FROM invoice) AS max_invoice_date,
        CASE 
            WHEN MAX(i.invoice_date) <= DATE_SUB((SELECT MAX(invoice_date) FROM invoice), INTERVAL 6 MONTH) THEN 'Churned'
            ELSE 'Active'
        END AS customer_status -- Identify churned vs active customers
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    join invoice_line il on il.invoice_id=i.invoice_id
    GROUP BY c.customer_id, c.country
)
SELECT 
    country,
    COUNT(customer_id) AS total_customers,
    COUNT(CASE WHEN customer_status = 'Churned' THEN 1 END) AS churned_customers,
    ROUND(AVG(total_spent), 2) AS avg_lifetime_value, 
    ROUND(AVG(total_purchases), 0) AS avg_purchase_count,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    CASE 
        WHEN COUNT(CASE WHEN customer_status = 'Churned' THEN 1 END) > (COUNT(customer_id) * 0.5) 
        THEN 'High Churn Risk'
        ELSE 'Low Churn Risk'
    END AS churn_risk_category
FROM CustomerMetrics
GROUP BY country
order by churn_risk_category, country;
    
-- 10. How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?
select * from Album;
alter table album add column ReleaseYear INTEGER;

-- 11. Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. 
-- They want to know the average total amount spent by customers from each country, along with the number of customers 
-- and the average number of tracks purchased per customer. Write an SQL query to provide this information.

select 
	billing_country as country,
	count(distinct i.customer_id) as total_customers,
	round(avg(total_spent),2) as avg_total_spent_per_customer,
    round(avg(track_count),0) as avg_tracks_per_customer
from invoice i 
join (
	select 
		customer_id,
		sum(il.unit_price*quantity) as total_spent,
        count(t.track_id) AS track_count
	from 
		invoice i 
	join invoice_line il on i.invoice_id=il.invoice_id
    join track t on t.track_id = il.track_id
	group by 1
) t on i.customer_id=t.customer_id
group by billing_country
order by avg_total_spent_per_customer desc; 










