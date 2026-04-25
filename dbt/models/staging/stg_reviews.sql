{{ config(materialized='view') }}

-- Staging model for reviews
-- Cleans and enriches review data

with source as (
    select * from {{ source('yelp', 'reviews') }}
),

cleaned as (
    select
        review_id,
        user_id,
        business_id,
        stars,
        useful,
        funny,
        cool,
        text as review_text,
        date as review_date,
        year as review_year,
        month as review_month,
        
        -- Add computed fields
        useful + funny + cool as total_votes,
        
        -- Sentiment categorization based on stars
        case
            when stars >= 4 then 'positive'
            when stars = 3 then 'neutral'
            else 'negative'
        end as sentiment,
        
        -- Review text length
        length(text) as review_length,
        
        current_timestamp as dbt_updated_at
        
    from source
)

select * from cleaned
