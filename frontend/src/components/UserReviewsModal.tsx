import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { YelpApiService } from '../services/api';
import { Review, User } from '../types/api';

interface UserReviewsModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: User;
}

const UserReviewsModal: React.FC<UserReviewsModalProps> = ({ isOpen, onClose, user }) => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const limit = 20;

  // Note: Removed cacheKey for now since it's not being used in the current implementation

  const loadReviews = useCallback(async (reset = false) => {
    if (loading) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const currentOffset = reset ? 0 : offset;
      const filters = { skip: currentOffset, limit };
      const data = await YelpApiService.getReviewsByUser(user.user_id, filters);
      
      if (data && data.length >= 0) {
        if (reset) {
          setReviews(data);
          setOffset(limit);
        } else {
          setReviews(prev => [...prev, ...data]);
          setOffset(prev => prev + limit);
        }
        
        // Check if we have more reviews to load
        setHasMore(data.length === limit);
      } else {
        setError('No reviews found for this user');
        setHasMore(false);
      }
    } catch (err) {
      console.error('Error loading user reviews:', err);
      setError('Failed to load reviews. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [user.user_id, offset, loading, limit]);

  // Load reviews when modal opens or user changes
  useEffect(() => {
    if (isOpen && user.user_id) {
      setReviews([]);
      setOffset(0);
      setHasMore(true);
      loadReviews(true);
    }
  }, [isOpen, user.user_id, loadReviews]);

  const loadMoreReviews = useCallback(() => {
    if (hasMore && !loading) {
      loadReviews(false);
    }
  }, [hasMore, loading, loadReviews]);

  const formatDate = (dateString: string | undefined) => {
    if (!dateString) return 'No date';
    return new Date(dateString).toLocaleDateString();
  };

  const renderStars = (rating: number) => {
    return '⭐'.repeat(Math.floor(rating)) + (rating % 1 ? '✨' : '');
  };

  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={handleBackdropClick}>
      <div className="modal-content user-reviews-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>
            {user.name ? `${user.name}'s Reviews` : `User Reviews`}
            <span className="review-count">({user.review_count || 0} total)</span>
          </h2>
          <button className="modal-close" onClick={onClose} aria-label="Close modal">
            ✕
          </button>
        </div>

        <div className="user-info-header">
          <div className="user-stats">
            <span className="user-name">{user.name || 'Anonymous User'}</span>
            {user.yelping_since && (
              <span className="yelping-since">Member since {formatDate(user.yelping_since)}</span>
            )}
          </div>
          <div className="user-engagement">
            {user.fans !== null && user.fans !== undefined && (
              <span className="fans">❤️ {user.fans} fans</span>
            )}
            {user.useful !== null && user.useful !== undefined && (
              <span className="useful">👍 {user.useful}</span>
            )}
            {user.funny !== null && user.funny !== undefined && (
              <span className="funny">😄 {user.funny}</span>
            )}
            {user.cool !== null && user.cool !== undefined && (
              <span className="cool">😎 {user.cool}</span>
            )}
          </div>
        </div>

        <div className="modal-body">
          {loading && reviews.length === 0 && (
            <div className="loading-state">
              <div className="loading-spinner"></div>
              <p>Loading {user.name ? `${user.name}'s` : 'user'} reviews...</p>
            </div>
          )}

          {error && reviews.length === 0 && (
            <div className="error-state">
              <p className="error-message">{error}</p>
              <button onClick={() => loadReviews(true)} className="retry-button">
                Try Again
              </button>
            </div>
          )}

          {reviews.length > 0 && (
            <div className="reviews-list">
              {reviews.map((review, index) => (
                <div key={`${review.review_id}-${index}`} className="review-card">
                  <div className="review-header">
                    <div className="business-info">
                      <h4 className="business-name">
                        {review.business_name || 'Business'}
                      </h4>
                    </div>
                    <div className="review-meta">
                      <div className="rating">
                        {renderStars(review.stars || 0)}
                        <span className="rating-number">({review.stars || 0}/5)</span>
                      </div>
                      <div className="review-date">
                        📅 {review.date ? formatDate(review.date) : 'No date'}
                      </div>
                    </div>
                  </div>

                  {review.text && (
                    <div className="review-text">
                      <p>{review.text}</p>
                    </div>
                  )}

                  <div className="review-feedback">
                    {(review.useful || 0) > 0 && (
                      <span className="feedback-stat useful">
                        👍 {review.useful} useful
                      </span>
                    )}
                    {(review.funny || 0) > 0 && (
                      <span className="feedback-stat funny">
                        😄 {review.funny} funny
                      </span>
                    )}
                    {(review.cool || 0) > 0 && (
                      <span className="feedback-stat cool">
                        😎 {review.cool} cool
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          {reviews.length > 0 && hasMore && (
            <div className="load-more-container">
              <button 
                onClick={loadMoreReviews} 
                disabled={loading}
                className="load-more-button"
              >
                {loading ? 'Loading more reviews...' : 'Load More Reviews'}
              </button>
            </div>
          )}

          {reviews.length > 0 && !hasMore && (
            <div className="end-of-reviews">
              <p>You've seen all of {user.name ? `${user.name}'s` : 'this user\'s'} reviews!</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default UserReviewsModal;