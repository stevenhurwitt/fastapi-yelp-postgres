
    
    

select
    business_id as unique_field,
    count(*) as n_records

from "steven"."public_marts"."business_analytics"
where business_id is not null
group by business_id
having count(*) > 1


