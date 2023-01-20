use danny_dinner;
/* Question 1
What is the total amount each customer spent at the restaurant? */

SELECT s.customer_id,
       Sum(m.price) AS Amount_spent
FROM   sales AS s
       JOIN menu m
         ON s.product_id = m.product_id
GROUP  BY s.customer_id; 

/* Question 2
How many days has each customer visited the restaurant? */

SELECT customer_id,
       Count(DISTINCT order_date) AS No_of_days_visited
FROM   sales
GROUP  BY customer_id; 

/* Question 3
What was the first item from the menu purchased by each customer? */

SELECT customer_id,
       product_name
FROM   (SELECT s.customer_id,
               m.product_name,
               s.order_date,
               Dense_rank()
                 OVER(
                   partition BY s.customer_id
                   ORDER BY s.order_date) AS rnk
        FROM   sales s
               INNER JOIN menu m
                       ON s.product_id = m.product_id
        GROUP  BY customer_id,
                  product_name,
                  order_date) t
WHERE  rnk = 1; 
    
/* Question 4
What is the most purchased item on the menu and how many times was it purchased by all customers? */

SELECT m.product_name, COUNT(s.product_id) AS No_of_purchase
FROM sales s
JOIN menu m 
	ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/* Question 5
Which item was the most popular for each customer? */

WITH t
     AS (SELECT s.customer_id,
                m.product_name,
                Count(s.product_id)                    AS order_count,
                Rank()
                  OVER(
                    partition BY s.customer_id
                    ORDER BY Count(s.product_id) DESC) AS rnk
         FROM   sales s
                INNER JOIN menu m
                        ON s.product_id = m.product_id
         GROUP  BY product_name,
                   customer_id)
SELECT customer_id,
       product_name,
       order_count
FROM   t
WHERE  rnk = 1; 

/* Question 6
Which item was purchased first by the customer after they became a member? */

SELECT t.customer_id,
       t.product_name
FROM   (SELECT s.customer_id,
               s.order_date,
               m.product_name
        FROM   sales s
               JOIN menu m
                 ON s.product_id = m.product_id) t
       JOIN members b
         ON t.customer_id = b.customer_id
WHERE  t.order_date >= b.join_date
GROUP  BY 1
ORDER  BY 1; 

/* Question 7
Which item was purchased just before the customer became a member? */

WITH t
     AS (SELECT s.customer_id,
                m.product_name,
                Dense_rank()
                  OVER (
                    partition BY s.customer_id
                    ORDER BY s.order_date) AS rnk
         FROM   sales s
                JOIN menu m
                  ON s.product_id = m.product_id
                JOIN members mb
                  ON mb.customer_id = s.customer_id
         WHERE  s.order_date < mb.join_date)
SELECT customer_id,
       product_name
FROM   t
WHERE  rnk = 1;

/* Question 8
What is the total items and amount spent for each member before they became a member? */

SELECT s.customer_id,
       Count(s.product_id) AS no_of_products,
       Sum(m.price)        AS amount_spent
FROM   sales s
       JOIN menu m
         ON s.product_id = m.product_id
       JOIN members mb
         ON mb.customer_id = s.customer_id
WHERE  s.order_date < mb.join_date
GROUP  BY s.customer_id
ORDER  BY s.customer_id; 

/* Question 9
If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */

SELECT s.customer_id,
       Sum(CASE
             WHEN m.product_name = 'sushi' THEN m.price * 2 * 10
             ELSE m.price * 10
           END) AS total_points
FROM   sales s
       JOIN menu m
         ON s.product_id = m.product_id
GROUP  BY s.customer_id; 

/* Question 10
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January? */

WITH dates
     AS (SELECT *,
                Date_add(join_date, interval 7 day) AS valid_date,
                Last_day(join_date)                 AS last_date
         FROM   members)
SELECT s.customer_id,
       SUM(CASE
             WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN
             m.price * 20
           END) AS total_points
FROM   dates d
       join sales s
         ON s.customer_id = d.customer_id
       join menu m
         ON m.product_id = s.product_id
WHERE  s.order_date <= d.last_date
GROUP  BY s.customer_id; 

/* Bonus Question
	Joining all table*/

SELECT s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       ( CASE
           WHEN s.order_date >= mb.join_date THEN 'Y'
           ELSE 'N'
         END ) AS member
FROM   sales s
       LEFT JOIN menu m
              ON s.product_id = m.product_id
       LEFT JOIN members mb
              ON mb.customer_id = s.customer_id; 

/* Bonus Question
	Ranking all rows in the universal table*/

WITH new_table
     AS (SELECT s.customer_id,
                s.order_date,
                m.product_name,
                m.price,
                ( CASE
                    WHEN s.order_date >= mb.join_date THEN 'Y'
                    ELSE 'N'
                  END ) AS member
         FROM   sales s
                LEFT JOIN menu m
                       ON s.product_id = m.product_id
                LEFT JOIN members mb
                       ON mb.customer_id = s.customer_id)
SELECT *,
       ( CASE
           WHEN member = "n" THEN "null"
           ELSE Rank()
                  OVER (
                    partition BY customer_id, member
                    ORDER BY order_date)
         END ) AS ranking
FROM   new_table; 