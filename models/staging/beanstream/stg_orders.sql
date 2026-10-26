with stg_orders as (
    select
        cast(order_id as integer) as order_id,
        cast(customer_id as integer) as customer_id,
        cast(order_date as date) as order_date,
        trim(lower(status)) as order_status,
        trim(lower(channel)) as channel
    from {{ source('beanstream_raw', 'orders') }}
)

select
    order_id,
    customer_id,
    order_date,
    order_status,
    channel
from stg_orders