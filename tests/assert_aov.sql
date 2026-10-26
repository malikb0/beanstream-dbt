-- tests/assert_aov.sql
with aov_calc as (
    select round(sum(line_amount) / count(distinct order_id), 2) as actual_aov
    from {{ ref('fct_sales') }}
    where order_status <> 'cancelled'
)
select *
from aov_calc
where abs(actual_aov - 73.35) > 0.01
