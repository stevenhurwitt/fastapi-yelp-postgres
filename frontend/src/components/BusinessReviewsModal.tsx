import React, { useState, useEffect } from 'react';
import { Review, SearchFilters } from '../types/api';
import { YelpApiService } from '../services/api';

interface BusinessReviewsModalProps {
  businessId: string;
  businessName: string;
  isOpen: boolean;
  onClose: () => void;
}

const BusinessReviewsModal: React.FC<BusinessReviewsModalProps> = ({
  businessId,
  businessName,
  isOpen,
  onClose
}) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<SearchFilters>({
    skip: 0,
    limit: 20
  });

  useEffect(() => {
    if (isOpen && businessId) {
      loadReviews();
    }
  }, [isOpen, businessId, filters]);

  const loadReviews = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await YelpApiService.getReviewsByBusiness(businessId, filters);
      setReviews(data);
    } catch (err) {
      setError('Failed to load reviews');
      console.error('Error loading reviews:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadMore = () => {
    setFilters({ ...filters, skip: (filters.skip || 0) + (filters.limit || 20) });
  };

  const renderStars = (stars: number) => {
    const fullStars = Math.floor(stars);
    const hasHalfStar = stars % 1 !== 0;
    const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return (
      <>
        {'⭐'.repeat(fullStars)}
        {hasHalfStar && '⭐'}
        {'☆'.repeat(emptyStars)}
      </>
    );
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString();
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Reviews for {businessName}</h2>
          <button className="modal-close" onClick={onClose}>
            ✕
          </button>
        </div>

        <div className="modal-body">
          {loading && <div className="loading">Loading reviews...</div>}
          
          {error && <div className="error">{error}</div>}

          {!loading && !error && reviews.length === 0 && (
            <div className="no-results">No reviews found for this business.</div>
          )}

          {!loading && reviews.length > 0 && (
            <>
              <div className="reviews-summary">
                <p>Showing {reviews.length} reviews</p>
              </div>

              <div className="reviews-list">
                {reviews.map((review) => (
                  <div key={review.review_id} className="review-card">
                    <div className="review-header">
                      <div className="review-user">
                        <strong>{review.user_name || 'Anonymous User'}</strong>
                      </div>
                      <div className="review-rating">
                        {renderStars(review.stars || 0)}
                        <span className="stars-number">({review.stars || 0})</span>
                      </div>
                      <div className="review-date">
                        {review.date && formatDate(review.date)}
                      </div>
                    </div>
                    <div className="review-text">
                      {review.text}
                    </div>
                    {(review.useful || 0) > 0 && (
                      <div className="review-feedback">
                        👍 {review.useful} found this useful
                        {(review.funny || 0) > 0 && ` • 😄 ${review.funny} found this funny`}
                        {(review.cool || 0) > 0 && ` • 😎 ${review.cool} found this cool`}
                      </div>
                    )}
                  </div>
                ))}
              </div>

              {reviews.length >= (filters.limit || 20) && (
                <div className="load-more-reviews">
                  <button onClick={loadMore} disabled={loading}>
                    {loading ? 'Loading...' : 'Load More Reviews'}
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default BusinessReviewsModal;