import React, { useState, useEffect } from 'react';
import { Review, SearchFilters } from '../types/api';
import { YelpApiService } from '../services/api';

interface ReviewListProps {
  businessId?: string;
  userId?: string;
}

const ReviewList: React.FC<ReviewListProps> = ({ businessId, userId }) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<SearchFilters>({
    skip: 0,
    limit: 10
  });

  useEffect(() => {
    loadReviews();
  }, [filters, businessId, userId]);

  const loadReviews = async () => {
    try {
      setLoading(true);
      setError(null);
      let data: Review[];
      
      if (businessId) {
        data = await YelpApiService.getReviewsByBusiness(businessId, filters);
      } else if (userId) {
        data = await YelpApiService.getReviewsByUser(userId, filters);
      } else {
        // The regular reviews endpoint now includes user and business names
        data = await YelpApiService.getReviews(filters);
      }
      
      setReviews(data);
    } catch (err) {
      setError('Failed to load reviews');
      console.error('Error loading reviews:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadMore = () => {
    setFilters({ ...filters, skip: (filters.skip || 0) + (filters.limit || 10) });
  };

  const renderStars = (stars?: number) => {
    if (!stars) return null;
    return '⭐'.repeat(Math.round(stars)) + ` ${stars}`;
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString();
  };

  const truncateText = (text?: string, maxLength: number = 200) => {
    if (!text) return '';
    return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
  };

  if (loading && reviews.length === 0) {
    return <div className="loading">Loading reviews...</div>;
  }

  return (
    <div className="review-list">
      <h2>
        {businessId ? 'Business Reviews' : userId ? 'User Reviews' : 'Latest Reviews'}
      </h2>

      {error && <div className="error">{error}</div>}

      <div className="reviews">
        {reviews.map((review) => (
          <div key={review.review_id} className="review-card">
            <div className="review-header">
              <div className="stars">{renderStars(review.stars)}</div>
              <div className="date">{formatDate(review.date)}</div>
              <div className="engagement">
                {review.useful ? `👍 ${review.useful}` : ''} 
                {review.funny ? ` 😄 ${review.funny}` : ''} 
                {review.cool ? ` 😎 ${review.cool}` : ''}
              </div>
            </div>
            <div className="review-text">
              {truncateText(review.text)}
            </div>
            <div className="review-meta">
              {review.user_name ? (
                <small>By: {review.user_name}</small>
              ) : (
                <small>User ID: {review.user_id}</small>
              )}
              {!businessId && review.business_name && (
                <small> | Business: {review.business_name}</small>
              )}
              {!businessId && !review.business_name && (
                <small> | Business ID: {review.business_id}</small>
              )}
            </div>
          </div>
        ))}
      </div>

      {reviews.length > 0 && (
        <div className="load-more">
          <button onClick={loadMore} disabled={loading}>
            {loading ? 'Loading...' : 'Load More'}
          </button>
        </div>
      )}
    </div>
  );
};

export default ReviewList;
