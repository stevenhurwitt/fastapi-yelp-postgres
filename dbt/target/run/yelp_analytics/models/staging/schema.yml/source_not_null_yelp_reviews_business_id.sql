
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select business_id
from "yelp"."public"."reviews"
where business_id is null



  
  
      
    ) dbt_internal_test