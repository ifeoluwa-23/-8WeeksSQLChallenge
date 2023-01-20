## 8 Weeks SQL Challenge

![Case 1 pix](https://user-images.githubusercontent.com/123111536/213601909-8a1c9873-c037-4884-aea6-664680608cc2.png)

## :bookmark_tabs: Table of Contents
- 🛠️ Problem Statement
- 📂 Dataset
- 📙 Case Study Questions
- 🏆 Solutions

## :hammer_and_wrench: Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, 
how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers 
will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally 
he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are 
enough for you to write fully functioning SQL queries to help him answer his questions!

## :open_file_folder: Dataset
We were provided with three datasets:
 - Sales
 <details><summary>View Table</summary>
<p>
  
 | customer_id | order_date | product_id |
| :---         | :---      |     :--- |
| A   | 2021-01-01  | 1  |
| A   | 2021-01-01  | 2  |
| A   | 2021-01-07  | 2  |
| A   | 2021-01-10  | 3  |
| A   | 2021-01-11  | 3  |
| A   | 2021-01-11  | 3  |
| B   | 2021-01-01  | 2  |
| B   | 2021-01-02  | 2  |
| B   | 2021-01-04  | 1  |
| B   | 2021-01-11  | 1  |
| B   | 2021-01-16  | 3  |
| B   | 2021-02-01  | 3  |
| C   | 2021-01-01  | 1  |
| C   | 2021-01-01  | 3  |
| C   | 2021-02-07  | 3  |
  
</p>
</details>

 - Menu
 <details><summary>View Table</summary>
<p>
  
 | product_id | product_name | price |
| :---         | :---      |     :--- |
| 1   | sushi  | 10  |
| 2   | curry  | 15  |
| 3   | ramen  | 12  |

  </p>
</details>

 - Members
 <details><summary>View Table</summary>
<p> 
  
 | customer_id | join_date |
| :---         | :---      |  
| A   | 2021-01-07  |
| B   | 2021-01-09  |

</p>
</details>

## :closed_book: Case Study Questions
Each of the following case study questions can be answered using a single SQL statement:
 <details><summary>View List of Questions</summary>
<p> 

  1. What is the total amount each customer spent at the restaurant?
  2. How many days has each customer visited the restaurant?
  3. What was the first item from the menu purchased by each customer?
  4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  5. Which item was the most popular for each customer?
  6. Which item was purchased first by the customer after they became a member?
  7. Which item was purchased just before the customer became a member?
  8. What is the total items and amount spent for each member before they became a member?
  9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
  10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
  11. Use the available data to create a comprehensive data using the Join function.
  12. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

</p>
</details>

 ## 	:trophy: Solutions
 <details><summary>View Solution</summary>
<p> 
  
   1. What is the total amount each customer spent at the restaurant?
   
   ```bash
SELECT s.customer_id,
       Sum(m.price) AS Amount_spent
FROM   sales AS s
       JOIN menu m
         ON s.product_id = m.product_id
GROUP  BY s.customer_id; 
```
  2. How many days has each customer visited the restaurant?
   
```bash
SELECT customer_id,
       Count(DISTINCT order_date) AS No_of_days_visited
FROM   sales
GROUP  BY customer_id; 
```
   
  3. What was the first item from the menu purchased by each customer?
   
```bash
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
```
   
  4. What is the most purchased item on the menu and how many times was it purchased by all customers?
   
```bash
SELECT m.product_name,
       Count(s.product_id) AS No_of_purchase
FROM   sales s
       JOIN menu m
         ON s.product_id = m.product_id
GROUP  BY 1
ORDER  BY 2 DESC
LIMIT  1; 
```
   
  5. Which item was the most popular for each customer?
   
```bash
WITH t
     AS (SELECT s.customer_id,
                m.product_name,
                Count(s.product_id) AS order_count,
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
```
    
   6. Which item was purchased first by the customer after they became a member?
   
```bash
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
```
   
  7. Which item was purchased just before the customer became a member?
   
```bash
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
```
   
  8. What is the total items and amount spent for each member before they became a member?
   
```bash
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
```
   
  9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
   
```bash
SELECT s.customer_id,
       Sum(CASE
             WHEN m.product_name = 'sushi' THEN m.price * 2 * 10
             ELSE m.price * 10
           END) AS total_points
FROM   sales s
       JOIN menu m
         ON s.product_id = m.product_id
GROUP  BY s.customer_id; 
```
   
 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
   
```bash
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
```
   
  11. Use the available data to create a comprehensive data using the Join function.
   
```bash
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
```

  12. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
   
```bash
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
```
 
  </p>
</details>
