
  
    

  create  table "steven"."public_marts"."user_insights__dbt_tmp"
  
  
    as
  
  (
    

-- User insights mart
-- Comprehensive user behavior and engagement metrics

with user_base as (
    select * from "steven"."public_staging"."stg_users"
),

review_activity as (
    select
        user_id,
        count(*) as reviews_written,
        avg(stars) as avg_stars_given,
        sum(total_votes) as total_review_votes,
        count(distinct business_id) as businesses_reviewed,
        max(review_date) as last_review_date,
        min(review_date) as first_review_date,
        
        -- Sentiment distribution
        sum(case when sentiment = 'positive' then 1 else 0 end) as positive_reviews_written,
        sum(case when sentiment = 'negative' then 1 else 0 end) as negative_reviews_written
        
    from "steven"."public_staging"."stg_reviews"
    group by user_id
),

tip_activity as (
    select
        user_id,
        count(*) as tips_written,
        sum(compliment_count) as tip_compliments_received
    from "steven"."public_staging"."stg_tips"
    group by user_id
),

final as (
    select
        u.user_id,
        u.user_name,
        u.review_count as profile_review_count,
        u.yelping_since,
        u.years_yelping,
        u.fans,
        u.is_elite,
        u.average_stars as profile_avg_stars,
        
        -- Engagement metrics
        u.total_votes_received as profile_votes,
        u.total_compliments,
        
        -- Activity metrics
        coalesce(r.reviews_written, 0) as actual_reviews_written,
        coalesce(r.avg_stars_given, 0) as calculated_avg_stars,
        coalesce(r.total_review_votes, 0) as review_votes_received,
        coalesce(r.businesses_reviewed, 0) as unique_businesses_reviewed,
        r.last_review_date,
        r.first_review_date,
        
        -- Tip metrics
        coalesce(t.tips_written, 0) as tips_written,
        coalesce(t.tip_compliments_received, 0) as tip_compliments,
        
        -- Sentiment analysis
        coalesce(r.positive_reviews_written, 0) as positive_reviews,
        coalesce(r.negative_reviews_written, 0) as negative_reviews,
        
        -- User categorization
        case
            when u.is_elite and r.reviews_written >= 100 then 'Elite Power User'
            when r.reviews_written >= 100 then 'Power User'
            when r.reviews_written >= 20 then 'Active User'
            when r.reviews_written > 0 then 'Casual User'
            else 'Inactive User'
        end as user_tier,
        
        -- Engagement score (weighted combination of metrics)
        (
            coalesce(r.reviews_written, 0) * 2 +
            coalesce(t.tips_written, 0) +
            coalesce(u.fans, 0) * 3 +
            coalesce(u.total_compliments, 0) +
            case when u.is_elite then 50 else 0 end
        ) as engagement_score,
        
        -- Positivity ratio
        case 
            when r.reviews_written > 0 
            then round((r.positive_reviews_written::numeric / r.reviews_written::numeric) * 100, 2)
            else 0 
        end as positivity_percentage,
        
        current_timestamp as dbt_updated_at
        
    from user_base u
    left join review_activity r on u.user_id = r.user_id
    left join tip_activity t on u.user_id = t.user_id
)

select * from final
  );
  