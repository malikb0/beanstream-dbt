with stg_products as (
    select
        cast(product_id as integer) as product_id,
        trim(product_name) as product_name,
        trim(category) as category,
        cast(unit_price as numeric(10,2)) as unit_price,
        active as active
    from {{ source('beanstream_raw', 'products') }}
)

select
    product_id,
    product_name,
    category,
    unit_price,
    active
from stg_products