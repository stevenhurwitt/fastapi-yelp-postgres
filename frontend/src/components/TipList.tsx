import React, { useState, useEffect } from 'react';
import { Tip, SearchFilters } from '../types/api';
import { YelpApiService } from '../services/api';

const TipList: React.FC = () => {
  const [tips, setTips] = useState<Tip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<SearchFilters>({
    skip: 0,
    limit: 20
  });
  const [minCompliments, setMinCompliments] = useState<number | ''>('');
  const [selectedYear, setSelectedYear] = useState<number | ''>('');

  useEffect(() => {
    loadTips();
  }, [filters]);

  const loadTips = async () => {
    try {
      setLoading(true);
      setError(null);
      let data = await YelpApiService.getTips(filters);
      
      // Client-side filtering for now (could be moved to backend later)
      if (minCompliments !== '') {
        data = data.filter(tip => (tip.compliment_count || 0) >= minCompliments);
      }
      if (selectedYear !== '') {
        data = data.filter(tip => tip.year === selectedYear);
      }
      
      setTips(data);
    } catch (err) {
      setError('Failed to load tips');
      console.error('Error loading tips:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    setFilters({ ...filters, skip: 0 });
  };

  const handleClearFilters = () => {
    setMinCompliments('');
    setSelectedYear('');
    setFilters({ skip: 0, limit: 20 });
  };

  const loadMore = () => {
    setFilters({ ...filters, skip: (filters.skip || 0) + (filters.limit || 20) });
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString();
  };

  const truncateText = (text?: string, maxLength: number = 150) => {
    if (!text) return '';
    return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
  };

  const getAvailableYears = () => {
    // Generate years from 2004 to current year (Yelp was founded in 2004)
    const currentYear = new Date().getFullYear();
    const years = [];
    for (let year = currentYear; year >= 2004; year--) {
      years.push(year);
    }
    return years;
  };

  const renderComplimentBadge = (count?: number) => {
    if (!count || count === 0) return null;
    return (
      <div className="compliment-badge">
        👏 {count} compliment{count !== 1 ? 's' : ''}
      </div>
    );
  };

  if (loading && tips.length === 0) {
    return (
      <div className="loading">
        <p>Loading tips...</p>
        <p><small>⏳ Large datasets may take 1-2 minutes to load</small></p>
      </div>
    );
  }

  return (
    <div className="tip-list">
      <div className="search-controls">
        <h2>Yelp Tips</h2>
        <div className="filters">
          <input
            type="number"
            placeholder="Min compliments"
            min="0"
            value={minCompliments}
            onChange={(e) => setMinCompliments(e.target.value ? Number(e.target.value) : '')}
          />
          <select
            value={selectedYear}
            onChange={(e) => setSelectedYear(e.target.value ? Number(e.target.value) : '')}
          >
            <option value="">All years</option>
            {getAvailableYears().map(year => (
              <option key={year} value={year}>{year}</option>
            ))}
          </select>
          <button onClick={handleSearch}>Search</button>
          <button onClick={handleClearFilters}>Clear</button>
        </div>
      </div>

      {error && <div className="error">{error}</div>}

      <div className="tips">
        {tips.map((tip, index) => (
          <div key={`${tip.user_id}-${tip.business_id}-${index}`} className="tip-card">
            <div className="tip-header">
              <div className="tip-date">
                📅 {formatDate(tip.date)}
                {tip.year && <span className="year-badge">{tip.year}</span>}
              </div>
              {renderComplimentBadge(tip.compliment_count)}
            </div>
            
            <div className="tip-text">
              {truncateText(tip.text)}
            </div>
            
            <div className="tip-meta">
              <div className="tip-names">
                {tip.user_name ? (
                  <small>👤 By: {tip.user_name}</small>
                ) : (
                  <small>👤 User: {tip.user_id?.substring(0, 8)}...</small>
                )}
                {tip.business_name ? (
                  <small>🏪 At: {tip.business_name}</small>
                ) : (
                  <small>🏪 Business: {tip.business_id?.substring(0, 8)}...</small>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {tips.length === 0 && !loading && (
        <div className="no-results">
          <p>No tips found matching your criteria.</p>
          <p>Try adjusting your filters or clearing them to see more results.</p>
        </div>
      )}

      {tips.length > 0 && (
        <div className="load-more">
          <button onClick={loadMore} disabled={loading}>
            {loading ? 'Loading...' : 'Load More'}
          </button>
        </div>
      )}
    </div>
  );
};

export default TipList;
