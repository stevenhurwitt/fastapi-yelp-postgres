
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- Custom data quality test
-- Tests that review counts match between business table and actual reviews

select
    b.business_id,
    b.listed_review_count,
    b.actual_review_count,
    abs(b.listed_review_count - b.actual_review_count) as difference
from "steven"."public_marts"."business_analytics" b
where abs(b.listed_review_count - b.actual_review_count) > 10
  
  
      
    ) dbt_internal_test