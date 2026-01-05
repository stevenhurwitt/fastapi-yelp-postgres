{{ config(
    materialized='table',
    indexes=[
      {'columns': ['month', 'city']},
      {'columns': ['month', 'state']},
    ]
) }}

-- Review trends mart
-- Time-series analysis of review patterns

with reviews_with_business as (
    select
        r.review_id,
        r.review_date,
        r.review_year,
        r.review_month,
        r.stars,
        r.sentiment,
        r.total_votes,
        r.review_length,
        b.city,
        b.state,
        b.categories,
        b.category_array
    from {{ ref('stg_reviews') }} r
    inner join {{ ref('stg_businesses') }} b on r.business_id = b.business_id
),

monthly_trends as (
    select
        date_trunc('month', review_date)::date as month,
        city,
        state,
        
        -- Volume metrics
        count(*) as review_count,
        count(distinct review_id) as unique_reviews,
        
        -- Rating metrics
        avg(stars) as avg_stars,
        
        -- Sentiment metrics
        sum(case when sentiment = 'positive' then 1 else 0 end) as positive_count,
        sum(case when sentiment = 'neutral' then 1 else 0 end) as neutral_count,
        sum(case when sentiment = 'negative' then 1 else 0 end) as negative_count,
        
        -- Engagement metrics
        avg(total_votes) as avg_votes_per_review,
        sum(total_votes) as total_votes,
        
        -- Content metrics
        avg(review_length) as avg_review_length,
        
        current_timestamp as dbt_updated_at
        
    from reviews_with_business
    group by 
        date_trunc('month', review_date)::date,
        city,
        state
)

select * from monthly_trends
order by month desc, city
