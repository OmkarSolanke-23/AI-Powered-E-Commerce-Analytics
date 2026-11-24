
CREATE DATABASE ecommerce_analytics;

USE ecommerce_analytics; 

CREATE TABLE ecommerce_sales (
    order_id VARCHAR(20),
    order_date DATE,
    customer_id VARCHAR(20),
    product_name VARCHAR(100),
    category VARCHAR(50),
    quantity INT,
    price DECIMAL(12,2),
    discount DECIMAL(5,2),
    region VARCHAR(50),
    payment_method VARCHAR(50),
    status VARCHAR(30),
    total_sales DECIMAL(12,2),
    discount_amount DECIMAL(12,2),
    net_revenue DECIMAL(12,2),
    year INT,
    month INT,
    day INT,
    day_name VARCHAR(20),
    month_year VARCHAR(10)
); 


SELECT COUNT(*)
FROM final_processed_ecommerce; 

describe final_processed_ecommerce;

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(total_sales) AS total_sales,
    SUM(discount_amount) AS total_discount,
    SUM(net_revenue) AS total_net_revenue,
    AVG(net_revenue) AS average_order_revenue
FROM final_processed_ecommerce; 

-- Category-wise Revenue Analysis 
SELECT
    category,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_sales), 2) AS gross_sales,
    ROUND(SUM(discount_amount), 2) AS total_discount,
    ROUND(SUM(net_revenue), 2) AS net_revenue
FROM final_processed_ecommerce
GROUP BY category
ORDER BY net_revenue DESC;

-- Top 10 products by revenu 

SELECT
    product_name,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_sales), 2) AS gross_sales,
    ROUND(SUM(discount_amount), 2) AS total_discount,
    ROUND(SUM(net_revenue), 2) AS net_revenue
FROM final_processed_ecommerce
GROUP BY product_name
ORDER BY net_revenue DESC
LIMIT 10;

-- Region-wise performance
SELECT
    region,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_sales), 2) AS gross_sales,
    ROUND(SUM(discount_amount), 2) AS total_discount,
    ROUND(SUM(net_revenue), 2) AS net_revenue
FROM final_processed_ecommerce
GROUP BY region
ORDER BY net_revenue DESC; 

-- Monthly revenue analysis
SELECT
    year,
    month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(net_revenue), 2) AS monthly_revenue
FROM final_processed_ecommerce
GROUP BY year, month
ORDER BY year, month; 

-- Month-over-Month (MoM) revenue growth
WITH monthly AS (
    SELECT
        year,
        month,
        SUM(net_revenue) AS monthly_revenue
    FROM final_processed_ecommerce
    GROUP BY year, month
),

monthly_growth AS (
    SELECT
        year,
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_revenue
    FROM monthly
)

SELECT
    year,
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (monthly_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS growth_percentage
FROM monthly_growth
ORDER BY year, month;

-- Order status performance 
SELECT
    status,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        (SELECT COUNT(DISTINCT order_id)
         FROM final_processed_ecommerce),
        2
    ) AS order_percentage,
    ROUND(SUM(net_revenue), 2) AS net_revenue
FROM final_processed_ecommerce
GROUP BY status
ORDER BY total_orders DESC; 

-- Payment method analysis 
SELECT
    payment_method,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        (SELECT COUNT(DISTINCT order_id)
         FROM final_processed_ecommerce),
        2
    ) AS order_percentage,
    ROUND(SUM(net_revenue), 2) AS net_revenue
FROM final_processed_ecommerce
GROUP BY payment_method
ORDER BY net_revenue DESC; 

-- Customer revenue analysis 

SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(net_revenue), 2) AS total_revenue,
    ROUND(AVG(net_revenue), 2) AS average_order_revenue
FROM final_processed_ecommerce
WHERE customer_id != 'Unknown'
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10; 

-- Repeat customer analysis 

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM final_processed_ecommerce
    WHERE customer_id != 'Unknown'
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders; 

-- Discount impact analysis 
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.10 THEN 'Low Discount'
        WHEN discount <= 0.20 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_category,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(AVG(discount) * 100, 2) AS average_discount_percentage,

    ROUND(SUM(total_sales), 2) AS gross_sales,

    ROUND(SUM(discount_amount), 2) AS total_discount,

    ROUND(SUM(net_revenue), 2) AS net_revenue

FROM final_processed_ecommerce
GROUP BY discount_category
ORDER BY net_revenue DESC; 

 -- Customer spending segments 
 WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(net_revenue) AS total_spending
    FROM final_processed_ecommerce
    WHERE customer_id != 'Unknown'
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_spending >= 200000 THEN 'High'
        WHEN total_spending >= 100000 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(AVG(total_spending), 2) AS average_spending,

    ROUND(SUM(total_spending), 2) AS total_revenue

FROM customer_spending
GROUP BY customer_segment
ORDER BY total_revenue DESC;