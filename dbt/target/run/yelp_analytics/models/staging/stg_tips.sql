
  create view "steven"."public_staging"."stg_tips__dbt_tmp"
    
    
  as (
    

-- Staging model for tips
-- Cleans tip data

with source as (
    select * from "steven"."public"."tips"
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
  );