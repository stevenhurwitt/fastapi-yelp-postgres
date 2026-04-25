{{ config(
    materialized='table',
    indexes=[
      {'columns': ['category']},
      {'columns': ['city', 'category']},
    ]
) }}

-- Category analytics mart
-- Performance metrics by business category

with businesses_with_categories as (
    select
        business_id,
        business_name,
        city,
        state,
        is_currently_open,
        unnest(category_array) as category
    from {{ ref('stg_businesses') }}
    where category_array is not null
),

business_metrics as (
    select * from {{ ref('business_analytics') }}
),

category_stats as (
    select
        bc.category,
        bc.city,
        bc.state,
        
        -- Business counts
        count(distinct bc.business_id) as businesses_in_category,
        sum(case when bc.is_currently_open then 1 else 0 end) as open_businesses,
        
        -- Rating metrics
        avg(bm.calculated_avg_rating) as avg_category_rating,
        max(bm.calculated_avg_rating) as max_rating,
        min(bm.calculated_avg_rating) as min_rating,
        
        -- Volume metrics
        sum(bm.actual_review_count) as total_reviews,
        avg(bm.actual_review_count) as avg_reviews_per_business,
        sum(bm.total_tips) as total_tips,
        sum(bm.total_checkins) as total_checkins,
        
        -- Engagement
        sum(bm.total_engagement) as total_engagement,
        avg(bm.positive_review_percentage) as avg_positive_percentage,
        
        -- Top business
        max(bm.business_name) as top_rated_business,
        
        current_timestamp as dbt_updated_at
        
    from businesses_with_categories bc
    left join business_metrics bm on bc.business_id = bm.business_id
    group by bc.category, bc.city, bc.state
)

select * from category_stats
order by total_reviews desc
