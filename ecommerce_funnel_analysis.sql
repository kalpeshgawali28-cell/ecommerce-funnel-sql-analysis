1_Establish baseline revenue, volume, order value, and conversion performance.
SELECT 
COUNT(DISTINCT user_id) AS total_visitors,
COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders,
ROUND(SUM(amount), 2) AS total_sales,
ROUND(
	SUM(CASE WHEN event_type = 'purchase' THEN amount ELSE 0 END) 
	/ NULLIF(COUNT(CASE WHEN event_type = 'purchase' THEN 1 END), 0), 2
    ) AS average_order_value,
    ROUND(COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) * 100.0 / COUNT(DISTINCT user_id), 2) AS conversion_rate_percent
FROM user_events;

/*
Query 1 Insight:
- 5,000 unique visitors generated 826 orders ($87,975.11 total sales).
- Average Order Value is $106.51.
- Overall conversion rate is 16.52%.
*/

2.Locate where potential buyers leak out of the conversion funnel

with funnel_counts as (
select 
count(distinct case when event_type = 'page_view' then user_id end) as views,
count(distinct case when event_type = 'add_to_cart' then user_id end) as carts,
count(distinct case when event_type = 'checkout_start' then user_id end ) as checkouts,
count(distinct case when event_type = 'payment_info' then user_id end) as payments,
count(distinct case when event_type = 'purchase' then user_id end) as orders
from user_events
)
select views ,
carts,
round((carts*100/views), 2) as view_to_carts_pct,
round(100-(carts*100/views), 2) as view_dropoff_pct,
checkouts,
round((checkouts*100/carts), 2) as cart_to_checkout_pct,
payments,
round((payments*100/checkouts), 2) as checkout_to_payment_pct,
orders,
round((orders*100/payments), 2) as payment_to_order_pct
from funnel_counts;

/*
Query 2 Insight:
- Biggest bottleneck: 68.94% drop-off between product page view and add-to-cart.
- Checkout completion is high: 91.88% of users entering payment complete the purchase.
*/

3.Evaluate the quality and return on investment for each traffic source

select 
traffic_source,
count(distinct user_id) as visitors,
count(case when event_type = 'purchase' then 1 end) as orders,
round(count(case when event_type = 'purchase' then 1 end ) * 100/count(distinct user_id), 2) as conversion_rate_pct,
round(sum(amount), 2) as total_revenue,
round(sum(amount) / nullif(count(case when event_type='purchase' then 1 end), 0), 2) as aov
from user_events
group by traffic_source
order by total_revenue desc;

/*
Query 3 Insight:
Email drives the strongest results with a 33.91% conversion rate (over twice the site average).
Social Media brings 1,472 visitors but only 6.93% convert, showing low‑intent traffic from ads.
*/



4.Identify top-selling products and conversion efficiency by product ID.

select
 product_id,
 count(case when event_type = 'page_view' then 1 end) as views,
 count(case when event_type = 'purchase' then 1 end) as purchases,
 round(count(case when event_type ='purchase' then 1 end)*100/count(case when event_type='page_view' then 1 end ), 2) as view_to_purchase_rate,
 round(sum(amount), 2) as product_revenue 
 from user_events
 group by product_id
 order by product_revenue desc;

 /*
Query 4 Insight:
Demand is steady across products.
Product 205 leads with $15,905.07 revenue and the highest conversion rate (17.48%),
 while Product 201 shows the lowest conversion rate (15.49%) despite strong view counts.
  */

 

5.Build an audience segment of high-intent shoppers who added items to their cart but left before checkout.

select 
user_id,
traffic_source,
product_id,
max(event_date) as last_interaction
from user_events
where user_id in (
select distinct user_id from user_events where event_type= 'add_to_cart'
)
and user_id not in (
select distinct user_id from user_events where event_type = 'purchase'
)
group by user_id, traffic_source,product_id
order by last_interaction desc
limit 10; 

/*
Query 5 Insight:
- here are 450 users who added an item to their cart but never 
completed an order. This query exports their user_id, traffic
origin, and intended product so the marketing team can trigger
automated email recovery workflows

Final Business Recommendations
/*
1. Marketing: Reallocate budget from low-converting social ads (6.93%) into paid ads (21.07%) and email marketing (33.91%).
2. Product & UX: Optimize product display pages (reviews, clear pricing, badges) to fix the 68.94% view-to-cart drop-off.
3. Retention: Automate email reminders for the 450 users who abandoned their carts.
*/













