-- Test for orphaned tips (tips without matching users or businesses)

with missing_users as (
    select
        t.user_id,
        t.business_id,
        'missing_user' as issue_type
    from {{ ref('stg_tips') }} t
    left join {{ ref('stg_users') }} u on t.user_id = u.user_id
    where u.user_id is null
),

missing_businesses as (
    select
        t.user_id,
        t.business_id,
        'missing_business' as issue_type
    from {{ ref('stg_tips') }} t
    left join {{ ref('stg_businesses') }} b on t.business_id = b.business_id
    where b.business_id is null
)

select * from missing_users
union all
select * from missing_businesses
