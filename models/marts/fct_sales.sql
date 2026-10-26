-- models/marts/fct_sales.sql
{{ config(
    materialized='incremental',
    unique_key='order_item_id',
    incremental_strategy='delete+insert',
    on_schema_change='append_new_columns'
) }}
with order_lines as (
    select 
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.unit_price,
        o.customer_id,
        o.channel,
        o.order_status,
        o.order_date
    from {{ ref('stg_order_items') }} oi
    join {{ ref('stg_orders') }} o 
        on oi.order_id = o.order_id
),
final as (
    select 
        ol.order_item_id,
        ol.order_id,
        d.date_id,
        ol.customer_id,
        ol.product_id,
        c.channel_id,
        ol.order_status,
        ol.quantity,
        ol.unit_price,
        round(ol.quantity * ol.unit_price, 2) as line_amount
    from order_lines ol
    join {{ ref('dim_date') }} d 
        on d.full_date = ol.order_date
    join {{ ref('dim_channel') }} c 
        on c.channel = ol.channel
)
select 
    order_item_id,
    order_id,
    date_id,
    customer_id,
    product_id,
    channel_id,
    order_status,
    quantity,
    unit_price,
    line_amount
from final
{% if is_incremental() %}
where order_item_id > (select coalesce(max(order_item_id), 0) from {{ this }})
{% endif %}