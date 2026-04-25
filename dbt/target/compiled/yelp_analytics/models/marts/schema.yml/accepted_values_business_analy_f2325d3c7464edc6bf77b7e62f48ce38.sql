
    
    

with all_values as (

    select
        business_tier as value_field,
        count(*) as n_records

    from "steven"."public_marts"."business_analytics"
    group by business_tier

)

select *
from all_values
where value_field not in (
    'High Rated','Low Rated','Average Rated','Limited Reviews','No Reviews'
)


