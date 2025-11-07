USE sakila_project;

-- 1️ See all tables
SHOW TABLES;

-- 2️ Count rows in each table
SELECT 'actor' AS table_name, COUNT(*) FROM actor
UNION ALL SELECT 'film', COUNT(*) FROM film
UNION ALL SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'rental', COUNT(*) FROM rental
UNION ALL SELECT 'payment', COUNT(*) FROM payment;

-- 3️ Quick data preview
SELECT * FROM customer LIMIT 5;
SELECT * FROM film LIMIT 5;
SELECT * FROM rental LIMIT 5;

-- 1.What are the purchasing patterns of new customers versus repeat customers?

SELECT 
    CASE 
        WHEN rental_count = 1 THEN 'New Customer'
        ELSE 'Repeat Customer'
    END AS Customer_Type,
    COUNT(*) AS Total_Customers,
    CASE 
        WHEN rental_count = 1 THEN 'One-time purchase behavior'
        WHEN rental_count BETWEEN 2 AND 5 THEN 'Occasional renter (2–5 rentals)'
        WHEN rental_count BETWEEN 6 AND 10 THEN 'Frequent renter (6–10 rentals)'
        ELSE 'Highly loyal (10+ rentals)'
    END AS Purchasing_Pattern
FROM (
    SELECT 
        c.customer_id,
        COUNT(r.rental_id) AS rental_count
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    GROUP BY c.customer_id
) AS sub
GROUP BY Customer_Type, Purchasing_Pattern
ORDER BY Customer_Type, Purchasing_Pattern;

-- Which films have the highest rental rates and are most in demand?

SELECT 
    f.title AS Film_Title,
    f.rental_rate AS Rental_Rate,
    COUNT(r.rental_id) AS Total_Rentals
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title, f.rental_rate
ORDER BY f.rental_rate DESC, Total_Rentals DESC
LIMIT 10;

-- 3) Are there correlations between staff performance and customer satisfaction?
SELECT 
    s.staff_id,
    CONCAT(s.first_name, ' ', s.last_name) AS Staff_Name,
    COUNT(DISTINCT r.rental_id) AS Total_Rentals_Handled,
    COUNT(DISTINCT r.customer_id) AS Unique_Customers_Served,
    SUM(p.amount) AS Total_Revenue_Collected,
    ROUND(SUM(p.amount) / COUNT(DISTINCT r.customer_id), 2) AS Avg_Revenue_Per_Customer
FROM staff s
JOIN rental r ON s.staff_id = r.staff_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY s.staff_id, Staff_Name
ORDER BY Total_Revenue_Collected DESC;

-- 4) Are there seasonal trends in customer behavior across different locations?
SELECT 
    cty.city AS City,
    MONTH(STR_TO_DATE(r.rental_date, '%d-%m-%Y %H:%i')) AS Month_Number,
    DATE_FORMAT(STR_TO_DATE(r.rental_date, '%d-%m-%Y %H:%i'), '%M') AS Month_Name,
    COUNT(r.rental_id) AS Total_Rentals,
    ROUND(SUM(p.amount), 2) AS Total_Revenue
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
JOIN customer cust ON r.customer_id = cust.customer_id
JOIN store s ON cust.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city cty ON a.city_id = cty.city_id
GROUP BY City, Month_Number, Month_Name
ORDER BY City, Month_Number;

-- Question 5 — Are certain language films more popular among specific customer segments?
SELECT 
    l.name AS Film_Language,
    COUNT(r.rental_id) AS Total_Rentals,
    COUNT(DISTINCT r.customer_id) AS Unique_Customers,
    ROUND(SUM(p.amount), 2) AS Total_Revenue
FROM film f
JOIN language l ON f.language_id = l.language_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY l.name
ORDER BY Total_Rentals DESC;


-- Question 6 — How does customer loyalty impact sales revenue over time?

SELECT 
    CASE 
        WHEN cust_rentals.total_rentals = 1 THEN 'New Customer'
        WHEN cust_rentals.total_rentals BETWEEN 2 AND 5 THEN 'Moderately Loyal (2–5 rentals)'
        ELSE 'Highly Loyal (6+ rentals)'
    END AS Loyalty_Level,
    DATE_FORMAT(
        COALESCE(
            STR_TO_DATE(p.payment_date_1, '%d-%m-%Y %H:%i'),
            STR_TO_DATE(p.payment_date_1, '%Y-%m-%d %H:%i:%s')
        ),
        '%Y-%m'
    ) AS Year_Monthh,
    ROUND(SUM(p.amount), 2) AS Monthly_Revenue
FROM (
    SELECT 
        c.customer_id,
        COUNT(r.rental_id) AS total_rentals
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    GROUP BY c.customer_id
) AS cust_rentals
JOIN rental r ON cust_rentals.customer_id = r.customer_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY Loyalty_Level, Year_Monthh
ORDER BY Year_Monthh, Loyalty_Level;


-- Question 7 — Are certain film categories more popular in specific locations?

SELECT 
    cty.city AS City,
    cat.name AS Film_Category,
    COUNT(r.rental_id) AS Total_Rentals
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city cty ON a.city_id = cty.city_id
GROUP BY cty.city, cat.name
ORDER BY cty.city, Total_Rentals DESC;

-- 8. How does the availability and knowledge of staff affect customer ratings?
SELECT 
    CONCAT(s.first_name, ' ', s.last_name) AS Staff_Name,
    COUNT(DISTINCT r.rental_id) AS Total_Rentals_Handled,
    COUNT(DISTINCT r.customer_id) AS Unique_Customers_Served,
    ROUND(SUM(p.amount), 2) AS Total_Revenue_Collected,
    ROUND(SUM(p.amount) / COUNT(DISTINCT r.customer_id), 2) AS Avg_Payment_Per_Customer
FROM staff s
JOIN rental r ON s.staff_id = r.staff_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY s.staff_id, Staff_Name
ORDER BY Total_Revenue_Collected DESC;


-- 9.How does the proximity of stores to customers impact rental frequency?
SELECT 
    CASE 
        WHEN cust_city.city = store_city.city THEN 'Same City (Nearby Customer)'
        ELSE 'Different City (Distant Customer)'
    END AS Proximity_Type,
    COUNT(r.rental_id) AS Total_Rentals,
    COUNT(DISTINCT r.customer_id) AS Unique_Customers
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN store s ON c.store_id = s.store_id
JOIN address cust_addr ON c.address_id = cust_addr.address_id
JOIN city cust_city ON cust_addr.city_id = cust_city.city_id
JOIN address store_addr ON s.address_id = store_addr.address_id
JOIN city store_city ON store_addr.city_id = store_city.city_id
GROUP BY Proximity_Type
ORDER BY Total_Rentals DESC;

-- 10. Do specific film categories attract different age groups of customers?
SELECT 
    CASE 
        WHEN c.customer_id BETWEEN 1 AND 200 THEN 'Young (ID 1–200)'
        WHEN c.customer_id BETWEEN 201 AND 400 THEN 'Middle-Age (ID 201–400)'
        ELSE 'Senior (ID 401–600)'
    END AS Customer_Age_Group,
    cat.name AS Film_Category,
    COUNT(r.rental_id) AS Total_Rentals
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
GROUP BY Customer_Age_Group, Film_Category
ORDER BY Customer_Age_Group, Total_Rentals DESC;


-- 11. What are the demographics and preferences of the highest-spending customers?-- Step 1 + 2 combined:  Find top 10 spenders and their preferred film categories and locations
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS Customer_Name,
    cty.city AS City,
    ctr.country AS Country,
    cat.name AS Favorite_Category,
    ROUND(SUM(p.amount), 2) AS Total_Spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
JOIN address a ON c.address_id = a.address_id
JOIN city cty ON a.city_id = cty.city_id
JOIN country ctr ON cty.country_id = ctr.country_id
GROUP BY c.customer_id, Customer_Name, City, Country, Favorite_Category
ORDER BY Total_Spent DESC
LIMIT 10;

-- 12. How does the availability of inventory impact customer satisfaction and repeat business?
SELECT 
    f.title AS Film_Title,
    COUNT(i.inventory_id) AS Copies_Available,
    COUNT(r.rental_id) AS Total_Rentals,
    ROUND(SUM(p.amount), 2) AS Total_Revenue,
    ROUND(SUM(p.amount) / COUNT(DISTINCT r.customer_id), 2) AS Avg_Revenue_Per_Customer
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY f.title
ORDER BY Copies_Available DESC, Total_Rentals DESC
LIMIT 10;

-- 13. What are the busiest hours or days for each store location, and how does it impact staffing requirements?
SELECT 
    s.store_id AS Store_ID,
    DAYNAME(STR_TO_DATE(r.rental_date, '%d-%m-%Y %H:%i')) AS Day_Name,
    HOUR(STR_TO_DATE(r.rental_date, '%d-%m-%Y %H:%i')) AS Hour_Of_Day,
    COUNT(r.rental_id) AS Total_Rentals
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN store s ON c.store_id = s.store_id
GROUP BY s.store_id, Day_Name, Hour_Of_Day
ORDER BY s.store_id, Total_Rentals DESC
LIMIT 20;

-- 14. What are the cultural or demographic factors that influence customer preferences in different locations?
SELECT 
    ctr.country AS Country,
    cat.name AS Film_Category,
    COUNT(r.rental_id) AS Total_Rentals
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id
JOIN store s ON i.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city cty ON a.city_id = cty.city_id
JOIN country ctr ON cty.country_id = ctr.country_id
GROUP BY ctr.country, cat.name
ORDER BY ctr.country, Total_Rentals DESC;

-- 15. How does the availability of films in different languages impact customer satisfaction and rental frequency?
SELECT 
    l.name AS Film_Language,
    COUNT(DISTINCT f.film_id) AS Total_Films_Available,
    COUNT(r.rental_id) AS Total_Rentals,
    ROUND(SUM(p.amount), 2) AS Total_Revenue,
    ROUND(SUM(p.amount) / COUNT(DISTINCT r.customer_id), 2) AS Avg_Revenue_Per_Customer
FROM film f
JOIN language l ON f.language_id = l.language_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY l.name
ORDER BY Total_Rentals DESC;



