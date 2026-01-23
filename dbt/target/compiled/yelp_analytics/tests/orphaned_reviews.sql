-- Test for orphaned reviews (reviews without matching business)

select
    r.review_id,
    r.business_id
from "steven"."public_staging"."stg_reviews" r
left join "steven"."public_staging"."stg_businesses" b on r.business_id = b.business_id
where b.business_id is null