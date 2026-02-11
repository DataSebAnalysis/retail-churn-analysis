-- Purpose: Define database schema used for churn analysis

-- Data was cleaned and engineered in Python before loading into MySQL

create table customers (
customer_id int primary key,
first_purchase_date datetime,
last_purchase_date datetime,
days_since_last_purchase int,
churn_eligible int,
customer_status varchar (50),
total_revenue decimal (12,2),
total_invoice int);


create table transactions (
transaction_id bigint auto_increment primary key,
invoice VARCHAR(20),
stock_code VARCHAR(20),
description VARCHAR(255),
quantity INT,
price DECIMAL(10,2),
invoice_date DATETIME,
customer_id INT,
country VARCHAR(50),
foreign key (customer_id) references customers(customer_id)
);
