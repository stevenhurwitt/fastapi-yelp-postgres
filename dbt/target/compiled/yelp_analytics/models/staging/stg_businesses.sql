

-- Staging model for businesses
-- Cleans and standardizes the raw business data

with source as (
    select * from "steven"."public"."business"
),

cleaned as (
    select
        business_id,
        name as business_name,
        address,
        city,
        state,
        postal_code,
        latitude,
        longitude,
        stars,
        review_count,
        is_open,
        attributes,
        categories,
        hours,
        
        -- Add computed fields
        case 
            when is_open = 1 then true 
            else false 
        end as is_currently_open,
        
        -- Parse categories into array for easier filtering
        string_to_array(categories, ', ') as category_array,
        
        current_timestamp as dbt_updated_at
        
    from source
)

select * from cleaned