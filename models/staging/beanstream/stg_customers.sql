with stg_customers as (
    select
        cast(customer_id as integer) as customer_id,
        trim(lower(email)) as email,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        trim(city) as city,
        trim(country) as country,
        cast(signup_date as date) as signup_date
    from {{ source('beanstream_raw', 'customers') }}
)

select
    customer_id,
    email,
    first_name,
    last_name,
    city,
    country,
    signup_date
from stg_customers