-- Test for orphaned reviews (reviews without matching business)

select
    r.review_id,
    r.business_id
from {{ ref('stg_reviews') }} r
left join {{ ref('stg_businesses') }} b on r.business_id = b.business_id
where b.business_id is null
