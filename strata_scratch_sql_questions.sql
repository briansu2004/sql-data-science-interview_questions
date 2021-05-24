
-- Q:
-- Distance Per Dollar
-- You’re given a dataset of uber rides with the traveling distance (‘distance_to_travel’) and cost (‘monetary_cost’) for each ride. For each date, find the difference between the distance-per-dollar for that date and the average distance-per-dollar for that year-month. Distance-per-dollar is defined as the distance traveled divided by the cost of the ride.
-- The output should include the year-month (YYYY-MM) and the average difference in distance-per-dollar for said year-month as an absolute value rounded to the 2nd decimal. You should also count both success and failed request_status as the distance and cost values are populated for all ride requests. Also, assume that all dates are unique in the dataset. Order your results by earliest request date first.

-- table uber_request_logs
-- request_idint
-- request_datedatetime
-- request_statusvarchar
-- distance_to_travelfloat
-- monetary_costfloat
-- driver_to_client_distancefloat

-- solution:
-- select * from uber_request_logs;
with 

distance_per_dollar_daily_data as(
select
request_date,
extract(year from request_date) as year_number,
extract(month from request_date) as month_number,
sum(distance_to_travel) as total_distance_travel,
sum(monetary_cost) as total_cost,
(sum(distance_to_travel)/sum(monetary_cost)) as distance_per_dollar_daily
from uber_request_logs
group by request_date,2,3
),

avg_distance_per_dollar_monthly_data as(
select
concat(extract(year from request_date) ,'-', extract(month from request_date)) as year_month,
year_number,
month_number,
avg(distance_per_dollar_daily) as avg_distance_per_dollar_monthly
from distance_per_dollar_daily_data
group by concat(extract(year from request_date) ,'-', extract(month from request_date)),2,3
)

select
a.request_date,
-- b.year_month,
-- b.year_number, b.month_number,
round(abs(a.distance_per_dollar_daily - b.avg_distance_per_dollar_monthly)::decimal,2) as rate
from distance_per_dollar_daily_data a
left join
avg_distance_per_dollar_monthly_data b
on a.year_number = b.year_number and a.month_number = b.month_number
order by 1


-------------------------------------------------------------------------------------------------

-- Q.Popularity Percentage
-- Find the popularity percentage for each user on Facebook. The popularity percentage is defined as the total number of friends the user has divided by the total number of users on the platform, then converted into a percentage by multiplying by 100.
-- Output each user along with their popularity percentage. Order records in ascending order by user id.
-- The 'user1' and 'user2' column are pairs of friends.
-- table
-- user1	user2
-- 1	2
-- 1	3
-- 1	4
-- 1	5
-- 1	6
-- 2	6
-- 2	7
-- 3	8
-- 3	9


-- Solution

WITH all_users AS (
SELECT DISTINCT(user1) AS users
FROM facebook_friends
UNION
SELECT DISTINCT(user2)
FROM facebook_friends
ORDER BY users),

part1 AS(
SELECT user1 AS user, 
COUNT(user2) AS friends
FROM facebook_friends 
GROUP BY user1
ORDER BY user1),

part2 AS(
SELECT user2 AS user, 
COUNT(user1) AS friends
FROM facebook_friends
GROUP BY user2
ORDER BY user2)

SELECT final.user AS user1, 
(SUM(final.friends)*100 / (SELECT COUNT(*) FROM all_users))::DECIMAL AS popularity_percent
FROM(
SELECT * FROM part1
UNION
SELECT * FROM part2) final
GROUP BY final.user
ORDER BY final.user;


-------------------------------------------------------------------------------------------------
-- Q Highest Cost Orders
-- Find the customer with the highest total order cost between 2019-02-01 to 2019-05-01. Output their first name, total cost of their items, and the date.

-- For simplicity, you can assume that every first name in the dataset is unique.

--customers
-- idint
-- first_namevarchar
-- last_namevarchar
-- cityvarchar
-- addressvarchar
-- phone_numbervarchar

-- orders
-- idint
-- cust_idint
-- order_datedatetime
-- order_quantityint
-- order_detailsvarchar
-- order_cost

--solution


SELECT c1.first_name,
t1.order_date, 
t1.total_exp
FROM(
    SELECT cust_id,
    order_date,
    SUM(order_cost*order_quantity) AS total_exp,
    RANK() OVER (ORDER BY SUM(order_cost*order_quantity) DESC) AS highest_exp
    FROM orders
    WHERE order_date BETWEEN '2019-02-01' AND '2019-05-01'
    GROUP BY order_date, cust_id
    ORDER BY total_exp DESC) t1
JOIN customers AS c1
ON t1.cust_id = c1.id
WHERE highest_exp = 1

-------------------------------------------------------------------------------------------------
-- *******************
-- Acceptance Rate By Date https://platform.stratascratch.com/coding-question?id=10285&python=
-- What is the overall friend acceptance rate by date? Your output should have the rate of acceptances
--  by the date the request was sent. Order by the earliest date to latest.
-- Assume that each friend request starts by a user sending (i.e., user_id_sender) a friend request to another user 
-- (i.e., user_id_receiver) that's logged in the table with action = 'sent'. 
-- If the request is accepted, the table logs action = 'accepted'. 
-- If the request is not accepted, no record of action = 'accepted' is logged.
-- table
-- user_id_sender	user_id_receiver	date	action
-- ad4943sdz	948ksx123d	2020-01-04	sent
-- fg503kdsdd	ofp049dkd	2020-01-04	sent
-- dfdfxf9483	9djjjd9283	2020-01-04	sent
-- hh643dfert	847jfkf203	2020-01-04	sent
-- ad4943sdz	948ksx123d	2020-01-06	accepted
-- fffkfld9499	993lsldidif	2020-01-06	sent
-- fg503kdsdd	ofp049dkd	2020-01-10	accepted
-- fffkfld9499	993lsldidif	2020-01-10	accepted

-- my solution
with sent as (select * 
from fb_friend_requests
where action = 'sent'),

received as (select *
from fb_friend_requests
where action = 'accepted'),

combined as (
    select sent.date, sent.user_id_sender, sent.user_id_receiver,
 sent.action as sent_action, received.action as received_action
from sent 
left join received
on sent.user_id_sender = received.user_id_sender
and sent.user_id_receiver = received.user_id_receiver)

select date, sum(case when received_action is null then 0 else 1 end)*1.0 / count(*)
from combined
group by date

-- author's solution
SELECT a.date,
       count(b.user_id_receiver)/count(a.user_id_sender)::decimal AS percentage_acceptance
FROM
  (SELECT date, user_id_sender,
                user_id_receiver
   FROM fb_friend_requests
   WHERE action='sent' ) a
LEFT JOIN
  (SELECT date, user_id_sender,
                user_id_receiver
   FROM fb_friend_requests
   WHERE action='accepted' ) b ON a.user_id_sender=b.user_id_sender
AND a.user_id_receiver=b.user_id_receiver
GROUP BY a.date
-------------------------------------------------------------------------------------------------
