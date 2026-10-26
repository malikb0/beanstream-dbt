-- tests/assert_customers_count.sql
select *
from (
    select count(*) as customers
    from {{ ref('dim_customer') }}
) c
where customers != 40
