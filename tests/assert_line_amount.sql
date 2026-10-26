-- tests/assert_line_amount.sql
select 
    order_item_id,
    order_id,
    quantity,
    unit_price,
    line_amount
from {{ ref('fct_sales') }}
where abs(line_amount - (quantity * unit_price)) > 0.01
