import React, { useState, useEffect } from 'react';
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

  // Simple function to load more reviews (not useCallback to avoid dependency issues)
  const loadMoreReviews = async () => {
    if (loading) {
      console.log('⚠️ Already loading, skipping request');
      return;
    }
    
    console.log('🔍 loadMoreReviews called, current offset:', offset);
    setLoading(true);
    setError(null);
    
    try {
      const filters = { skip: offset, limit };
      
      console.log('🔍 Loading more reviews for user:', user.user_id, 'with filters:', filters);
      const data = await YelpApiService.getReviewsByUser(user.user_id, filters);
      console.log('📊 Received additional review data:', data);
      
      if (Array.isArray(data)) {
        console.log('✅ Data is array with length:', data.length);
        
        setReviews(prev => [...prev, ...data]);
        setOffset(prev => prev + limit);
        
        // Check if we have more reviews to load
        const hasMoreData = data.length === limit;
        setHasMore(hasMoreData);
        console.log('📈 Has more data:', hasMoreData);
      } else {
        console.error('❌ Invalid data format received:', data);
        setError('Invalid response format from server');
        setHasMore(false);
      }
    } catch (err) {
      console.error('❌ Error loading more reviews:', err);
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(`Failed to load more reviews: ${errorMessage}`);
    } finally {
      setLoading(false);
      console.log('✅ Loading complete, setting loading to false');
    }
  };

  // Load reviews when modal opens or user changes
  useEffect(() => {
    if (!isOpen || !user.user_id) return;
    
    console.log('🔄 Modal opened for user:', user.user_id);
    
    // Reset state
    setReviews([]);
    setOffset(0);
    setHasMore(true);
    setError(null);
    
    // Direct API call without using loadReviews callback
    let mounted = true;
    
    const fetchReviews = async () => {
      setLoading(true);
      
      try {
        const filters = { skip: 0, limit };
        console.log('🔍 Fetching reviews for:', user.user_id, filters);
        
        const data = await YelpApiService.getReviewsByUser(user.user_id, filters);
        console.log('📊 Reviews fetched:', data);
        
        if (!mounted) return;
        
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
        console.error('❌ Error fetching reviews:', err);
        if (mounted) {
          const errorMessage = err instanceof Error ? err.message : 'Unknown error';
          setError(`Failed to load reviews: ${errorMessage}`);
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    };
    
    fetchReviews();
    
    return () => {
      mounted = false;
    };
  }, [isOpen, user.user_id, limit]); // Simple dependencies

  const handleLoadMore = () => {
    if (hasMore && !loading) {
      loadMoreReviews();
    }
  };

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
              <button onClick={() => window.location.reload()} className="retry-button">
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