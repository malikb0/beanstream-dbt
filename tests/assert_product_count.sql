-- tests/assert_products_count.sql
select *
from (
    select count(*) as products
    from {{ ref('dim_product') }}
) p
where products != 12
