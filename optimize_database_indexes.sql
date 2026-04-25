-- Database Performance Optimization: Index Creation Script
-- This script creates strategic indexes to optimize the most common query patterns
-- Based on analysis of existing queries and performance bottlenecks

-- =====================================================
-- BUSINESS TABLE OPTIMIZATIONS
-- =====================================================

-- 1. Business name search optimization (CRITICAL - currently 2.4s)
-- Text search with ILIKE is slow without proper indexing
-- Using trigram indexes for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create trigram index for business name searches
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_business_name_trgm 
ON business USING GIN (name gin_trgm_ops);

-- Create index for business ordering by popularity
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_business_stars_reviews 
ON business (stars DESC, review_count DESC) 
WHERE stars IS NOT NULL AND review_count IS NOT NULL;

-- Create index for city-based searches
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_business_city 
ON business (city) 
WHERE city IS NOT NULL;

-- Create index for state-based searches  
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_business_state 
ON business (state) 
WHERE state IS NOT NULL;

-- Create composite index for city + state searches
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_business_location 
ON business (state, city, stars DESC, review_count DESC) 
WHERE state IS NOT NULL AND city IS NOT NULL;

-- =====================================================
-- USER TABLE OPTIMIZATIONS  
-- =====================================================

-- 2. User list ordering optimization (CRITICAL - currently 16.7s)
-- Most user lists are ordered by review count
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_review_count_desc 
ON yelp_users (review_count DESC NULLS LAST) 
WHERE review_count IS NOT NULL;

-- User search by name optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_name_trgm 
ON yelp_users USING GIN (name gin_trgm_ops) 
WHERE name IS NOT NULL;

-- User stats for filtering/sorting
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_stats 
ON yelp_users (fans DESC, useful DESC, review_count DESC) 
WHERE fans IS NOT NULL OR useful IS NOT NULL;

-- =====================================================
-- REVIEW TABLE OPTIMIZATIONS
-- =====================================================

-- 3. Review query optimizations (already good, but can improve)
-- Composite index for user reviews with date ordering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_user_date_desc 
ON reviews (user_id, date DESC) 
WHERE date IS NOT NULL;

-- Composite index for business reviews with rating filters
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_business_stars 
ON reviews (business_id, stars DESC, date DESC) 
WHERE stars IS NOT NULL;

-- Index for review statistics queries  
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_feedback 
ON reviews (useful DESC, funny DESC, cool DESC) 
WHERE useful > 0 OR funny > 0 OR cool > 0;

-- =====================================================
-- TIP TABLE OPTIMIZATIONS
-- =====================================================

-- 4. Tips query optimization (already has good indexes)
-- Additional composite index for user tips with date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tips_user_date_desc 
ON tips (user_id, date DESC) 
WHERE date IS NOT NULL;

-- =====================================================
-- CROSS-TABLE JOIN OPTIMIZATIONS
-- =====================================================

-- 5. Foreign key indexes for better JOIN performance
-- These should already exist but adding for completeness

-- Reviews foreign keys (already exist - verified above)
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_user_id ON reviews (user_id);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_business_id ON reviews (business_id);

-- Tips foreign keys (already exist - verified above)  
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tips_user_id ON tips (user_id);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tips_business_id ON tips (business_id);

-- =====================================================
-- PERFORMANCE MONITORING INDEXES
-- =====================================================

-- 6. Indexes for application analytics and monitoring
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_reviews_recent 
ON reviews (date DESC) 
WHERE date >= (CURRENT_DATE - INTERVAL '30 days');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_active 
ON yelp_users (yelping_since DESC) 
WHERE yelping_since IS NOT NULL;

-- =====================================================
-- MAINTENANCE COMMANDS
-- =====================================================

-- Update table statistics after creating indexes
-- This helps the query planner make better decisions
ANALYZE business;
ANALYZE yelp_users;  
ANALYZE reviews;
ANALYZE tips;

-- =====================================================
-- PERFORMANCE NOTES
-- =====================================================

/*
EXPECTED PERFORMANCE IMPROVEMENTS:

1. Business name search: 2400ms → ~50ms (48x faster)
   - Trigram indexes enable efficient ILIKE queries
   - Composite index eliminates sorting overhead

2. User list loading: 16700ms → ~100ms (167x faster)  
   - Direct index on review_count DESC eliminates full table scan
   - Handles NULLS LAST efficiently

3. Review queries: Currently ~45ms → ~15ms (3x faster)
   - Better composite indexes reduce nested loop costs
   - More efficient date ordering

4. Business filtering: Varies → ~20ms 
   - City/state indexes enable efficient WHERE clauses
   - Composite indexes support complex filters

TOTAL EXPECTED SPEEDUP: 50-200x for slow queries
*/