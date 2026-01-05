
    
    

with all_values as (

    select
        sentiment as value_field,
        count(*) as n_records

    from "steven"."public_staging"."stg_reviews"
    group by sentiment

)

select *
from all_values
where value_field not in (
    'positive','neutral','negative'
)


