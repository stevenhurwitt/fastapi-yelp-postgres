
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select city
from "steven"."public_marts"."review_trends"
where city is null



  
  
      
    ) dbt_internal_test