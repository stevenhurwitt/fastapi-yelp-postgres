
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select business_id
from "steven"."public_marts"."business_analytics"
where business_id is null



  
  
      
    ) dbt_internal_test