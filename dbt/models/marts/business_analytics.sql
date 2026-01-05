{{ config(
    materialized='table',
    indexes=[
      {'columns': ['business_id'], 'unique': True},
      {'columns': ['city', 'avg_rating']},
    ]
) }}

-- Business analytics mart
-- Comprehensive business metrics combining reviews, tips, and checkins

with business_base as (
    select * from {{ ref('stg_businesses') }}
),

review_metrics as (
    select
        business_id,
        count(*) as total_reviews,
        avg(stars) as avg_rating,
        count(distinct user_id) as unique_reviewers,
        sum(case when sentiment = 'positive' then 1 else 0 end) as positive_reviews,
        sum(case when sentiment = 'neutral' then 1 else 0 end) as neutral_reviews,
        sum(case when sentiment = 'negative' then 1 else 0 end) as negative_reviews,
        sum(total_votes) as total_engagement,
        avg(review_length) as avg_review_length,
        max(review_date) as last_review_date,
        min(review_date) as first_review_date
    from {{ ref('stg_reviews') }}
    group by business_id
),

tip_metrics as (
    select
        business_id,
        count(*) as total_tips,
        sum(compliment_count) as tip_compliments
    from {{ ref('stg_tips') }}
    group by business_id
),

checkin_metrics as (
    select
        business_id,
        count(*) as total_checkins
    from {{ ref('stg_checkins') }}
    group by business_id
),

final as (
    select
        b.business_id,
        b.business_name,
        b.address,
        b.city,
        b.state,
        b.postal_code,
        b.latitude,
        b.longitude,
        b.stars as listed_stars,
        b.review_count as listed_review_count,
        b.is_currently_open,
        b.categories,
        b.category_array,
        
        -- Review metrics
        coalesce(r.total_reviews, 0) as actual_review_count,
        coalesce(r.avg_rating, 0) as calculated_avg_rating,
        coalesce(r.unique_reviewers, 0) as unique_reviewers,
        coalesce(r.positive_reviews, 0) as positive_reviews,
        coalesce(r.neutral_reviews, 0) as neutral_reviews,
        coalesce(r.negative_reviews, 0) as negative_reviews,
        coalesce(r.total_engagement, 0) as total_engagement,
        coalesce(r.avg_review_length, 0) as avg_review_length,
        r.last_review_date,
        r.first_review_date,
        
        -- Tip metrics
        coalesce(t.total_tips, 0) as total_tips,
        coalesce(t.tip_compliments, 0) as tip_compliments,
        
        -- Checkin metrics
        coalesce(c.total_checkins, 0) as total_checkins,
        
        -- Calculated fields
        case 
            when r.total_reviews >= 50 and r.avg_rating >= 4.0 then 'High Rated'
            when r.total_reviews >= 50 and r.avg_rating < 3.0 then 'Low Rated'
            when r.total_reviews >= 50 then 'Average Rated'
            when r.total_reviews > 0 then 'Limited Reviews'
            else 'No Reviews'
        end as business_tier,
        
        -- Sentiment ratio
        case 
            when r.total_reviews > 0 
            then round((r.positive_reviews::numeric / r.total_reviews::numeric) * 100, 2)
            else 0 
        end as positive_review_percentage,
        
        current_timestamp as dbt_updated_at
        
    from business_base b
    left join review_metrics r on b.business_id = r.business_id
    left join tip_metrics t on b.business_id = t.business_id
    left join checkin_metrics c on b.business_id = c.business_id
)

select * from final
