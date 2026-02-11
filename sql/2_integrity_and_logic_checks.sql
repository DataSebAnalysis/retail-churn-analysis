-- Purpose: Validate data integrity before analytical queries

-- INTEGRITY CHECKS --

-- Row counts --
select
(select count(*) from customers),
(select count(*) from transactions);

-- Primary Key Validation --
select customer_id, count(*)
from customers
group by customer_id
having count(*)>1;

-- Churn Logic Validation --
select customer_id, customer_status, days_since_last_purchase
from customers
where 
(customer_status = 'Churned' and days_since_last_purchase <175)
or (customer_status = 'At Risk' and (days_since_last_purchase <70 or days_since_last_purchase >=175))
or (customer_status = 'Active' and days_since_last_purchase >=70);

-- Churn Eligibility Distribution --
select churn_eligible, count(*) AS customers
from customers
group by churn_eligible;

-- Referential Integrity Check --
select count(*) as missing_transactions
from transactions t
left join customers c
on t.customer_id=c.customer_id
where c.customer_id is null;