{{ config(materialized='view') }}

-- Staging model for tips
-- Cleans tip data

with source as (
    select * from {{ source('yelp', 'tips') }}
),

cleaned as (
    select
        user_id,
        business_id,
        text as tip_text,
        date as tip_date,
        compliment_count,
        year as tip_year,
        
        -- Add computed fields
        length(text) as tip_length,
        
        current_timestamp as dbt_updated_at
        
    from source
)

select * from cleaned
