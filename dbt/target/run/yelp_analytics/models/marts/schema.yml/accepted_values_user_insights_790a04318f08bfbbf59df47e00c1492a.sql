
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        user_tier as value_field,
        count(*) as n_records

    from "steven"."public_marts"."user_insights"
    group by user_tier

)

select *
from all_values
where value_field not in (
    'Elite Power User','Power User','Active User','Casual User','Inactive User'
)



  
  
      
    ) dbt_internal_test