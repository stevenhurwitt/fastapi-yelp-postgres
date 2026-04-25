
    
    

select
    business_id as unique_field,
    count(*) as n_records

from "steven"."public_staging"."stg_businesses"
where business_id is not null
group by business_id
having count(*) > 1


