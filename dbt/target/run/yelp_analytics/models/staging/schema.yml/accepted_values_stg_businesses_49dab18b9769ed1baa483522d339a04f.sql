
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        stars as value_field,
        count(*) as n_records

    from "steven"."public_staging"."stg_businesses"
    group by stars

)

select *
from all_values
where value_field not in (
    '0','0.5','1','1.5','2','2.5','3','3.5','4','4.5','5'
)



  
  
      
    ) dbt_internal_test