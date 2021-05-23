--
-- Cracking the SQL Interview for Data Scientists
-- https://sqlpad.io/playground/

Q. Write a query to return the top 5 artists in the US and UK yesterday.

S:
with 
artist_ranking as
(
	select 
		a.artist_id,
		max(a.artist_name) as artist_name,
		max(p.country) as country
		row_number() over(partition by country order by sum(play_count) desc) as ranking
	from daily_plays p
	inner join artists a 
	on a.artist_id = p.artist_id
	where p.country in ('UK', 'US')
	and p.date=current_date-1
	group by a.artist_id
)
select artist_id,
artist_name,
country,
ranking 
from artist_ranking
where ranking <=5
limit 5;

-- https://sqlpad.io/playground/
Q: compare each movie DVDs replacement cost to the average cost of movies sharing
the same MPAA ratings

S: 
select
title,
rating,
replacement_cost,
avg(replacement_cost) over(partition by rating) as avg_cost
from film;

-- https://sqlpad.io/playground/
Q: compare every movie’s length (in
minutes) to the maximum length of movies from the same category.

select
title,
name,
length,
max(length) over(partition by name) as max_length
from(
select
f.title, c.category_name, f.length
from film f
inner join film_category fc
on fc.film_id = f.film_id
inner join category c
on c.category_id = fc.category_id
) tbl;

Q:overall progress for binge watching all films
S:
select
film_id,
title,
length,
sum(length) over(order by film_id) as running_total,
sum(length) over() as overall,
sum(length) over(order by film_id) * 100.0/sum(length) over() as running_percentage
from film 
order by film_id;


-- Section 1 window functions - Basic aggregation


Q. Percentage of revenue per movie --revenue (film_id x) * 100.0/ revenue of all movies
S:
-- select
-- film_id,
-- sum(amount) over(order by film_id) as revenue_per_film,
-- sum(amount) over() as overall,
-- sum(amount) over(order by film_id) *100.0/sum(amount) over() as revenue_percentage
-- from inventory i
-- inner join (
-- 	select
-- 	inventory_id,
-- 	customer_id
-- 	amount
-- 	from rental r 
-- 	inner join payment p
--     on p.customer_id = r.customer_id
--     )
with 
movie_revenue as(
select
	i.film_id,
	sum(p.amount) as revenue
	from payment p
	inner join rental r
	on p.rental_id = r.rental_id
	inner join inventory i
	on i.inventory_id = r.inventory_id
	group by i.film_id
)
select
film_id,
revenue*100./sum(revenue) over() revenue_percentage
from movie_revenue
order by film_id
limit 10

Q58: Percentage of revenue per movie by category m
S:
with 
movie_revenue as(
	i.film_id,
	-- fc.category_name -- but this will grouped in two film and category but what we need is revenue by film 
	-- in later query to calculate the total revenue by category we will consider the sum(amount)grup by category
	sum(p.amount) as revenue
	from payment p
	inner join rental r
	on p.rental_id = r.rental_id
	inner join inventory i
	on i.inventory_id = r.inventory_id
	-- inner join film_category fc
	-- on fc.film_id=i.film_id
	group by i.film_id
)
select
mr.film_id,
fc.name as category_name,
revenue*100.0/ sum(revenue) over(partition by c.name) as revenue_percent_category
from movie_revenue mr
inner join film_category fc
on fc.film_id=i.film_id
inner join category c 
on c.category_id = fc.category_id
order by film_id
limit 10

Q59: Movie rentals and average rentals in the same category
--Write a query to return the number of rentals per movie, 
--and the average number of rentals in its same category

-- with 
-- movie_rental_data as(
-- 	select
-- 	film_id,
-- 	count(rental_id) as rental_count
-- 	from rental r
-- 	inner join inventory i 
-- 	on r.inventory_id=i.inventory_id
-- 	group by 1
-- )
-- select
-- i.film_id,
-- c.name,
-- mrd.rental_count,
-- count(rental_id) over(partition by category_id)*100.0/count(rental_id) as avg_rental_count
-- from movie_rental_data mrd
-- inner join rental r
-- on r.film_id = mrd.film_id
-- inner join inventory i
-- on i.film_id = r.film_id
-- inner join film_category fc
-- on fc.film_id = i.film_id
-- inner join category c
-- on c.category_id=fc.category_id
-- group by 1,2,3
-- limit 10;

with
movie_rental_data as(
	select
		i.film_id,
		count(*) from rental_count
	from rental r
	inner join inventory i
	on i.inventory_id=r.inventory_id
	group by i.film_id
)

select
film_id,
category_name,
rental_count,
avg_rental_category
from
	(
		select
			mrd.film_id,
			c.name,
			rental_count,
			avg(rental_count) over(partition by c.name) avg_rental_category
		from movie_rental_data mrd
		inner join film_category fc 
		on fc.film_id = mrd.film_id
		inner join category c
		on c.category_id = fc.category_id) tbl
	where film_id<=10;


Q60:. Customer spend vs average spend in the same store difficult
-- Instruction
-- • Write a query to return a customer's life time value for the following: customer_id IN
-- (1, 100, 101, 200, 201, 300, 301, 400, 401, 500).
-- • Add a column to compute the average LTV of all customers from the same store.
-- • Return 4 columns: customer_id, store_id, customer total spend, average customer
-- spend from the same store.
-- • The order of your results doesn't matter

with 
customer_spend_data as(
select
c.customer_id,
max(c.store_id),-- assumming only one store per customer
sum(p.amount) as ltd_spend
from customer c
inner join payment p
on c.customer_id = p.customer_id
group by p.customer_id
)

select customer_id, store_id, ltd_spend, store_avg 
from
	(
		select
			customer_id,
			store_id,
			ltd_spend,
			avg(ltd_spend) over (partition by store_id) as avg
	    from customer_spend_data csp
	) tbl
where tbl.customer_id IN (1,100,101, 200, 201, 300,301, 400, 401, 500)
ORDER BY 1;

--  Section 2: ROW_NUMBER, RANK, DENSE_RANK

Q:create a row_number by length

select
f.film_id,
f.title,
f.length
row_number() over(order by length desc) as row_num
from film f
order by row_number


Q: create a row_number by length in a category

select
f.film_id,
f.title,
f.length,
c.name as category_name
row_number() over(partition by c.name order by f.length desc) row_num
from film f
inner join film_category fc
on fc.film_id=f.film_id
inner join category c
on c.category_id=fc.category_id
order by c.name,
row_number;


-- Q create a index
SELECT
 F.film_id,
 F.title,
 F.length,
 RANK() OVER(ORDER BY length DESC) AS ranking
FROM film F
ORDER BY ranking;

--  Q create index by category

SELECT
 F.film_id,
 F.title,
 F.length,
 C.name AS category,
 RANK() OVER(PARTITION BY C.name ORDER BY F.length DESC) ranking
FROM film F
INNER JOIN film_category FC
ON FC.film_id = F.film_id
INNER JOIN category C
ON C.category_id = FC.category_id
ORDER BY C.name, ranking

-- but rank will give same rank for same order by entry
-- . DENSE_RANK restarts with the following immediate consecutive value rather than creating a
-- gap.
-- As you can see here, for the first 2 rows, two movies both have a value of 1. Instead of restarting
-- from 3, the next dense_rank value starts as 2.

-- ie rank() 

-- length rank()
-- 185      1
-- 185		1
-- 175		3
-- 175 		3
-- 170		5
-- and dense_rank()
-- 185      1
-- 185		1
-- 175		2
-- 175 		2
-- 170		3


-- As you can see here, for the first 2 rows, two movies both have a value of 1. Instead of restarting
-- from 3, the next dense_rank value starts as 2.


--Similarly, we can also generate rankings within a subgroup with the help of PARTITION BY
Q. Shortest film by category
with Shortest_movie as (select
f.film_id,
f.title,
f.length,
c.name as category_name
ROW_NUMBER() over(partition by category_id order by  length desc) as ranking 
from film f
inner join film_category fc
on fc.film_id = f.film_id
inner join category c
on c.category_id = fc.category_id)
select
film_id,
 title,
 length,
 category,
 row_num
FROM movie_ranking
WHERE row_num = 1

Q:Top 5 customers by store
-- Write a query to return the top 5 customer ids and their rankings based on their spend
-- for each store.

with 
customer_spend_data as(
select
customer_id,
store_id,
sum(amount) as revenue
from payment p 
inner join customer c
on c.customer_id = p.customer_id
group by 1
)

select * from (
select 
store_id,
customer_id,
revenue,
dense_rank() over (partition by store_id order by revenue desc) as ranking
from customer_spend_data
) tbl
where ranking<=5;

-- QTop 2 films by category difficult
-- Instruction
-- • Write a query to return top 2 films based on their rental revenues in their category.
-- • A film can only belong to one category.
-- • The order of your results doesn't matter
WITH film_revenue AS (
 SELECT  F.film_id,
 MAX(C.name) AS category,
 SUM(P.amount) revenue
 FROM payment P
 INNER JOIN rental R
 ON R.rental_id = P.rental_id
 INNER JOIN inventory I
 ON I.inventory_id = R.inventory_id
 INNER JOIN film F
 ON F.film_id = I.film_id
 INNER JOIN film_category FC
 ON FC.film_id = F.film_id
 INNER JOIN category C
 ON C.category_id = FC.category_id
 GROUP BY F.film_id
)
SELECT * FROM (
 SELECT
 category,
 FR.film_id,
 revenue,
 ROW_NUMBER() OVER(PARTITION BY category ORDER BY revenue DESC) row_num
 FROM film_revenue FR
 INNER JOIN film_category FC
 ON FC.film_id = FR.film_id
 INNER JOIN category C
 ON C.category_id = FC.category_id
) X
WHERE row_num <= 2;

Question 69
-- Number of happy customers difficult
-- Instructions:
-- • Write a query to return the number of happy customers from May 24 (inclusive) to May
-- 31 (inclusive).
-- Definition
-- • Happy customer: customers who made at least 1 rental in each day of any 2
-- consecutive days.
WITH customer_rental_date AS (
SELECT
 customer_id,
 DATE(rental_ts) AS rental_date
FROM rental
WHERE DATE(rental_ts) >= '2020-05-24'
AND DATE(rental_ts) <= '2020-05-31'
GROUP BY
 customer_id,
 DATE(rental_ts)
),

customer_rental_date_diff as (
select
customer_id,
rental_date as customer_rental_date,
lag(rental_date, 1) over(partition by customer_id order by rental_date) as prev_rental_date
from customer_rental_date
)
select 
count(*) 
from 
(
	select 
customer_id,
min(customer_rental_date - prev_rental_date)
from customer_rental_date_diff
group by customer_id
having min(customer_rental_date - prev_rental_date)=1
) tbl
;

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
ORDER BY final.user









