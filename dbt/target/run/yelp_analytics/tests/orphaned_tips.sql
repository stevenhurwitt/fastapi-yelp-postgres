
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- Test for orphaned tips (tips without matching users or businesses)

with missing_users as (
    select
        t.user_id,
        t.business_id,
        'missing_user' as issue_type
    from "steven"."public_staging"."stg_tips" t
    left join "steven"."public_staging"."stg_users" u on t.user_id = u.user_id
    where u.user_id is null
),

missing_businesses as (
    select
        t.user_id,
        t.business_id,
        'missing_business' as issue_type
    from "steven"."public_staging"."stg_tips" t
    left join "steven"."public_staging"."stg_businesses" b on t.business_id = b.business_id
    where b.business_id is null
)

select * from missing_users
union all
select * from missing_businesses
  
  
      
    ) dbt_internal_test