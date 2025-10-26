import React, { useState, useEffect } from 'react';
import { Business, SearchFilters } from '../types/api';
import { YelpApiService } from '../services/api';

const BusinessList: React.FC = () => {
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<SearchFilters>({
    skip: 0,
    limit: 20
  });
  const [city, setCity] = useState('');
  const [minStars, setMinStars] = useState<number | ''>('');

  useEffect(() => {
    loadBusinesses();
  }, [filters]);

  const loadBusinesses = async () => {
    try {
      setLoading(true);
      setError(null);
      let data: Business[];
      
      if (city) {
        data = await YelpApiService.getBusinessesByCity(city, filters);
      } else if (minStars !== '') {
        data = await YelpApiService.getBusinessesByStars(Number(minStars), filters);
      } else {
        data = await YelpApiService.getBusinesses(filters);
      }
      
      setBusinesses(data);
    } catch (err) {
      setError('Failed to load businesses');
      console.error('Error loading businesses:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setFilters({ ...filters, skip: 0 });
  };

  const handleClearFilters = () => {
    setCity('');
    setMinStars('');
    setFilters({ skip: 0, limit: 20 });
  };

  const loadMore = () => {
    setFilters({ ...filters, skip: (filters.skip || 0) + (filters.limit || 20) });
  };

  const renderStars = (stars?: number) => {
    if (!stars) return null;
    return '⭐'.repeat(Math.round(stars)) + ` ${stars}`;
  };

  const renderCategories = (categories?: string) => {
    if (!categories) return null;
    return categories.split(', ').slice(0, 3).join(', ');
  };

  if (loading && businesses.length === 0) {
    return (
      <div className="loading">
        <p>Loading businesses...</p>
        <p><small>⏳ Large datasets may take 1-2 minutes to load</small></p>
      </div>
    );
  }

  return (
    <div className="business-list">
      <div className="search-controls">
        <h2>Yelp Businesses</h2>
        <div className="filters">
          <input
            type="text"
            placeholder="Search by city"
            value={city}
            onChange={(e) => setCity(e.target.value)}
          />
          <input
            type="number"
            placeholder="Min stars"
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

      <div className="business-grid">
        {businesses.map((business) => (
          <div key={business.business_id} className="business-card">
            <h3>{business.name}</h3>
            <div className="business-info">
              <div className="stars">{renderStars(business.stars)}</div>
              <div className="review-count">({business.review_count} reviews)</div>
              <div className="location">
                {business.address && <div>{business.address}</div>}
                <div>{business.city}, {business.state} {business.postal_code}</div>
              </div>
              <div className="categories">{renderCategories(business.categories)}</div>
              <div className="status">
                {business.is_open ? '🟢 Open' : '🔴 Closed'}
              </div>
            </div>
          </div>
        ))}
      </div>

      {businesses.length > 0 && (
        <div className="load-more">
          <button onClick={loadMore} disabled={loading}>
            {loading ? 'Loading...' : 'Load More'}
          </button>
        </div>
      )}
    </div>
  );
};

export default BusinessList;
