with distinct_channels as (
    select distinct trim(lower(channel)) as channel
    from {{ source('beanstream_raw', 'orders') }}
)

select
    row_number() over (order by channel)::integer as channel_id,
    channel
from distinct_channels