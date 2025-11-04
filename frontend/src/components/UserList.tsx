import React, { useState, useEffect } from 'react';
import { User, SearchFilters } from '../types/api';
import { YelpApiService } from '../services/api';
import UserReviewsModal from './UserReviewsModal';

const UserList: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<SearchFilters>({
    skip: 0,
    limit: 20
  });
  const [minReviews, setMinReviews] = useState<number | ''>('');
  const [minStars, setMinStars] = useState<number | ''>('');
  
  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  useEffect(() => {
    loadUsers();
  }, [filters]);

  const loadUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      let data = await YelpApiService.getUsers(filters);
      
      // Client-side filtering for now (could be moved to backend later)
      if (minReviews !== '') {
        data = data.filter(user => (user.review_count || 0) >= minReviews);
      }
      if (minStars !== '') {
        data = data.filter(user => (user.average_stars || 0) >= minStars);
      }
      
      setUsers(data);
    } catch (err) {
      setError('Failed to load users');
      console.error('Error loading users:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setFilters({ ...filters, skip: 0 });
  };

  const handleClearFilters = () => {
    setMinReviews('');
    setMinStars('');
    setFilters({ skip: 0, limit: 20 });
  };

  const loadMore = () => {
    setFilters({ ...filters, skip: (filters.skip || 0) + (filters.limit || 20) });
  };

  const renderStars = (stars?: number) => {
    if (!stars) return null;
    return '⭐'.repeat(Math.round(stars)) + ` ${stars.toFixed(1)}`;
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString();
  };

  const renderEliteYears = (elite?: string) => {
    if (!elite || elite === 'None') return null;
    const years = elite.split(',').filter(year => year.trim() !== '');
    if (years.length === 0) return null;
    return (
      <div className="elite-badge">
        🏆 Elite: {years.slice(0, 3).join(', ')}
        {years.length > 3 && ` +${years.length - 3} more`}
      </div>
    );
  };

  // Modal handlers
  const handleReviewsClick = (user: User) => {
    setSelectedUser(user);
    setIsModalOpen(true);
  };

  const handleModalClose = () => {
    setIsModalOpen(false);
    setSelectedUser(null);
  };

  const getTopCompliments = (user: User) => {
    const compliments = [
      { type: 'Funny', count: user.compliment_funny },
      { type: 'Cool', count: user.compliment_cool },
      { type: 'Hot', count: user.compliment_hot },
      { type: 'Profile', count: user.compliment_profile },
      { type: 'Writer', count: user.compliment_writer },
      { type: 'Photos', count: user.compliment_photos }
    ].filter(c => c.count && c.count > 0)
     .sort((a, b) => (b.count || 0) - (a.count || 0))
     .slice(0, 3);

    return compliments;
  };

  if (loading && users.length === 0) {
    return (
      <div className="loading">
        <p>Loading users...</p>
        <p><small>⏳ Large datasets may take 1-2 minutes to load</small></p>
      </div>
    );
  }

  return (
    <div className="user-list">
      <div className="search-controls">
        <h2>Yelp Users</h2>
        <div className="filters">
          <input
            type="number"
            placeholder="Min reviews"
            min="1"
            value={minReviews}
            onChange={(e) => setMinReviews(e.target.value ? Number(e.target.value) : '')}
          />
          <input
            type="number"
            placeholder="Min avg stars"
            min="1"
            max="5"
            step="0.1"
            value={minStars}
            onChange={(e) => setMinStars(e.target.value ? Number(e.target.value) : '')}
          />
          <button onClick={handleSearch}>Search</button>
          <button onClick={handleClearFilters}>Clear</button>
        </div>
      </div>

      {error && <div className="error">{error}</div>}

      <div className="user-grid">
        {users.map((user) => (
          <div key={user.user_id} className="user-card">
            <div className="user-header">
              <h3>{user.name || 'Anonymous User'}</h3>
              <div className="user-stats">
                <div 
                  className="review-count clickable" 
                  onClick={() => handleReviewsClick(user)}
                  title={`View all ${user.review_count || 0} reviews by ${user.name || 'this user'}`}
                >
                  📝 {user.review_count || 0} reviews
                </div>
                {user.average_stars && (
                  <div className="avg-stars">
                    {renderStars(user.average_stars)}
                  </div>
                )}
              </div>
            </div>

            <div className="user-info">
              {user.yelping_since && (
                <div className="yelping-since">
                  👤 Since: {formatDate(user.yelping_since)}
                </div>
              )}
              
              {user.fans !== null && user.fans !== undefined && (
                <div className="fans">
                  ❤️ {user.fans} fans
                </div>
              )}

              <div className="engagement-stats">
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

              {renderEliteYears(user.elite)}

              <div className="compliments">
                {getTopCompliments(user).map((compliment, index) => (
                  <span key={index} className="compliment-badge">
                    {compliment.type}: {compliment.count}
                  </span>
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>

      {users.length > 0 && (
        <div className="load-more">
          <button onClick={loadMore} disabled={loading}>
            {loading ? 'Loading...' : 'Load More'}
          </button>
        </div>
      )}

      {/* User Reviews Modal */}
      {selectedUser && (
        <UserReviewsModal
          isOpen={isModalOpen}
          onClose={handleModalClose}
          user={selectedUser}
        />
      )}
    </div>
  );
};

export default UserList;
