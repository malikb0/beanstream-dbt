-- tests/assert_customers_with_orders.sql
select *
from (
    select count(distinct customer_id) as customers_with_orders
    from {{ ref('fct_sales') }}
) c
where customers_with_orders != 39
