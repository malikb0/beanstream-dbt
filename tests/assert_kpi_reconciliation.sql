-- tests/assert_kpi_reconciliation.sql
with actual as (
    select 
        round(sum(line_amount), 2) as revenue,
        count(distinct order_id) as orders,
        sum(quantity) as units,
        (select count(*) from {{ ref('dim_customer') }}) as customers,
        (select count(*) from {{ ref('dim_product') }}) as products
    from {{ ref('fct_sales') }}
    where order_status != 'cancelled'
),
expected as (
    select metric, expected
    from {{ ref('expected_kpis') }}
)
select 
    e.metric,
    case e.metric
        when 'revenue' then a.revenue
        when 'orders' then a.orders
        when 'units' then a.units
        when 'customers' then a.customers
        when 'products' then a.products
    end as actual,
    e.expected
from expected e
cross join actual a
where abs(case e.metric
        when 'revenue' then a.revenue
        when 'orders' then a.orders
        when 'units' then a.units
        when 'customers' then a.customers
        when 'products' then a.products
    end - e.expected) > 0.01
