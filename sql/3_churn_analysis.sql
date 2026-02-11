-- Purpose: Segment customers and evaluate revenue impact across churn stages

-- ANALYSIS --

-- Q1 - What percentage of customers are churn-eligible based on inactivity thresholds?
select count(*) as total_customers,
sum(churn_eligible) as churned_customers,
(sum(churn_eligible)*100/count(*)) as churn_eligible_rate
from customers;

-- Q2 - What percentage of churn eligible customers are confirmed as churned?
select count(*) as total_customers,
sum(case when customer_status = 'Churned' then 1 else 0 end) as churned_customers,
sum(case when customer_status = 'Churned' then 1 else 0 end)*100/count(*) as churned_rate_pct
from customers
where churn_eligible = 1;

-- Q3 - How are churn-eligible customers and their total revenue distributed across churn stages?
select customer_status, 
count(*) as total_customers, 
count(*)*100/sum(count(*)) over () as pct_customers,
sum(total_revenue) as total_revenue,
sum(total_revenue)*100/sum(sum(total_revenue)) over () as pct_revenue
from customers
where churn_eligible = 1
group by customer_status
order by pct_revenue desc;

-- Q4 - Is customer churn risk associated with Average Order Value (AOV), when comparing customers in the lowest and highest AOV quartiles, considering only customers with at least two invoices?
with customers_aov as (
select customer_id,
total_invoice,
total_revenue,
total_revenue/ nullif(total_invoice, 0) as avg_order_value
from customers
where churn_eligible = 1
and total_invoice >= 2
),
aov_quartiles as (
select customer_id,
avg_order_value,
ntile(4) over (order by avg_order_value) as aov_quartile
from customers_aov
)
select aov_quartile,
count(*) as total_customers,
sum(case when c.customer_status = 'Churned' then 1 else 0 end) as churned_customers,
sum(case when c.customer_status = 'Churned' then 1 else 0 end)/count(*) as churn_rate
from aov_quartiles a
join customers c
on a.customer_id = c.customer_id
group by aov_quartile
order by aov_quartile;

-- Q5 - How does churn rate vary across customer quartiles based on purchase frequency (invoices per active month) among customers with at least two invoices?
with customer_activity as (
select customer_id,
total_invoice,
customer_status,
timestampdiff(month, first_purchase_date, last_purchase_date) + 1 as active_months
from customers
where churn_eligible = 1
and total_invoice >= 2
),
customer_frequency as (
select customer_id,
total_invoice,
customer_status,
active_months,
total_invoice/active_months as purchase_frequency
from customer_activity
),
frequency_quartiles as (
select customer_id,
purchase_frequency,
customer_status,
active_months,
ntile(4) over (order by purchase_frequency) as frequency_quartile
from customer_frequency
)
select frequency_quartile,
count(*) as total_customers,
avg(purchase_frequency) as avg_purchase_frequency,
avg(active_months) as avg_active_months,
sum(case when customer_status = 'Churned' then 1 else 0 end) as churned_customers,
sum(case when customer_status = 'Churned' then 1 else 0 end)/count(*) as churn_rate
from frequency_quartiles
group by frequency_quartile
order by frequency_quartile;

-- Q6 - Within each country, what proportion of churn-eligible customers and revenue is lost due to churn?
with customers_country as (
select distinct c.customer_id,
t.country,
c.customer_status,
c.total_revenue
from customers c
join transactions t
on c.customer_id = t.customer_id
where c.churn_eligible = 1
),
churn_metrics_by_country as (
select country,
count(customer_id) as total_customers,
sum(total_revenue) as total_revenue,
sum(case when customer_status = 'Churned' then 1 else 0 end) as churned_customers,
sum(case when customer_status = 'Churned' then total_revenue else 0 end) as churned_revenue
from customers_country
group by country
)
select
country,
total_customers,
churned_customers,
churned_customers/total_customers as churned_rate,
total_revenue,
churned_revenue,
churned_revenue/total_revenue as revenue_churn_rate
from churn_metrics_by_country
order by churned_revenue desc;

-- Q7 - Which customer segments account for the largest share of potential revenue loss, and therefore should be prioritized for retention efforts?
with base_customers as (
select customer_id,
total_revenue,
days_since_last_purchase
from customers
where churn_eligible = 1
),
segmented_customers as (
select customer_id,
total_revenue,
days_since_last_purchase,
ntile(4) over (order by total_revenue desc) as revenue_segment,
ntile(4) over (order by days_since_last_purchase desc) as inactivity_segment
from base_customers
)
select
revenue_segment,
inactivity_segment,
count(*) as total_customers,
avg(total_revenue) as avg_customer_revenue,
sum(total_revenue) as revenue_exposed_to_churn
from segmented_customers
group by revenue_segment, inactivity_segment
order by revenue_exposed_to_churn desc;