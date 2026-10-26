-- tests/assert_cancellation_rate.sql
with cancellation_rate as (
    select round(100.0 * count(distinct case when order_status = 'cancelled' then order_id end) / count(distinct order_id), 2) as actual_rate
    from {{ ref('fct_sales') }}
)
select *
from cancellation_rate
where abs(actual_rate - 17.5) > 0.01
