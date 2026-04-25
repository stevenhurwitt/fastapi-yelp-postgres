

-- Staging model for checkins

with source as (
    select * from "steven"."public"."checkins"
),

cleaned as (
    select
        business_id,
        date as checkin_date,
        
        current_timestamp as dbt_updated_at
        
    from source
)

select * from cleaned