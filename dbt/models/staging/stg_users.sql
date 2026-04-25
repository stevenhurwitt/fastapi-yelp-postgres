{{ config(materialized='view') }}

-- Staging model for users
-- Cleans and standardizes user data

with source as (
    select * from {{ source('yelp', 'yelp_users') }}
),

cleaned as (
    select
        user_id,
        name as user_name,
        review_count,
        yelping_since,
        friends,
        useful,
        funny,
        cool,
        fans,
        elite,
        average_stars,
        compliment_hot,
        compliment_more,
        compliment_profile,
        compliment_cute,
        compliment_list,
        compliment_note,
        compliment_plain,
        compliment_cool,
        compliment_funny,
        compliment_writer,
        compliment_photos,
        
        -- Add computed fields
        useful + funny + cool as total_votes_received,
        
        compliment_hot + compliment_more + compliment_profile + 
        compliment_cute + compliment_list + compliment_note + 
        compliment_plain + compliment_cool + compliment_funny + 
        compliment_writer + compliment_photos as total_compliments,
        
        -- Calculate tenure
        extract(year from age(current_date, yelping_since::date)) as years_yelping,
        
        -- Elite status
        case when elite is not null and elite != '' then true else false end as is_elite,
        
        current_timestamp as dbt_updated_at
        
    from source
)

select * from cleaned
