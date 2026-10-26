-- tests/assert_positive_quantity.sql
select 
    order_item_id,
    order_id,
    quantity
from {{ ref('fct_sales') }}
where quantity <= 0
