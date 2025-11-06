import React, { useState, useEffect, useCallback } from 'react';
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

  // Load reviews when modal opens or user changes
  useEffect(() => {
    if (isOpen && user.user_id) {
      console.log('🔄 Modal opened for user:', user.user_id);
      setReviews([]);
      setOffset(0);
      setHasMore(true);
      setError(null);
      
      // Load initial reviews
      const loadInitialReviews = async () => {
        setLoading(true);
        try {
          const filters = { skip: 0, limit };
          console.log('🔍 Loading initial reviews for user:', user.user_id);
          const data = await YelpApiService.getReviewsByUser(user.user_id, filters);
          
          if (Array.isArray(data)) {
            setReviews(data);
            setOffset(limit);
            setHasMore(data.length === limit);
            
            if (data.length === 0) {
              setError('This user has not written any reviews yet.');
            }
          } else {
            console.error('❌ Invalid data format received:', data);
            setError('Invalid response format from server');
          }
        } catch (err) {
          console.error('❌ Error loading initial reviews:', err);
          const errorMessage = err instanceof Error ? err.message : 'Unknown error';
          setError(`Failed to load reviews: ${errorMessage}`);
        } finally {
          setLoading(false);
        }
      };
      
      loadInitialReviews();
    }
  }, [isOpen, user.user_id, limit]);

  const loadMoreReviews = useCallback(async () => {
    if (!hasMore || loading) return;
    
    setLoading(true);
    try {
      const filters = { skip: offset, limit };
      console.log('🔍 Loading more reviews with offset:', offset);
      const data = await YelpApiService.getReviewsByUser(user.user_id, filters);
      
      if (Array.isArray(data)) {
        setReviews(prev => [...prev, ...data]);
        setOffset(prev => prev + limit);
        setHasMore(data.length === limit);
      } else {
        console.error('❌ Invalid data format for load more:', data);
        setHasMore(false);
      }
    } catch (err) {
      console.error('❌ Error loading more reviews:', err);
    } finally {
      setLoading(false);
      console.log('✅ Loading complete, setting loading to false');
    }
  }, [hasMore, loading, offset, user.user_id, limit]);

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
              <button 
                onClick={() => {
                  setReviews([]);
                  setOffset(0);
                  setHasMore(true);
                  setError(null);
                  
                  const retryLoad = async () => {
                    setLoading(true);
                    try {
                      const filters = { skip: 0, limit };
                      const data = await YelpApiService.getReviewsByUser(user.user_id, filters);
                      
                      if (Array.isArray(data)) {
                        setReviews(data);
                        setOffset(limit);
                        setHasMore(data.length === limit);
                        
                        if (data.length === 0) {
                          setError('This user has not written any reviews yet.');
                        }
                      } else {
                        setError('Invalid response format from server');
                      }
                    } catch (err) {
                      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
                      setError(`Failed to load reviews: ${errorMessage}`);
                    } finally {
                      setLoading(false);
                    }
                  };
                  
                  retryLoad();
                }} 
                className="retry-button"
              >
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
                onClick={handleLoadMore} 
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