with stg_order_items as (
    select
        cast(order_item_id as integer) as order_item_id,
        cast(order_id as integer) as order_id,
        cast(product_id as integer) as product_id,
        cast(quantity as integer) as quantity,
        cast(unit_price as numeric(10,2)) as unit_price,
        round(cast(quantity as numeric) * cast(unit_price as numeric), 2) as line_amount
    from {{ source('beanstream_raw', 'order_items') }}
)

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    line_amount
from stg_order_items