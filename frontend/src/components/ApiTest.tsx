import React, { useState, useEffect } from 'react';
import { YelpApiService } from '../services/api';

const ApiTest: React.FC = () => {
  const [apiStatus, setApiStatus] = useState<string>('Testing...');
  const [businessCount, setBusinessCount] = useState<number>(0);
  const [reviewCount, setReviewCount] = useState<number>(0);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    testApi();
  }, []);

  const testApi = async () => {
    try {
      setApiStatus('Connecting to API...');
      
      // Test health endpoint
      const health = await YelpApiService.healthCheck();
      setApiStatus(`API Health: ${health.status}`);
      
      // Test businesses endpoint
      const businesses = await YelpApiService.getBusinesses({ skip: 0, limit: 5 });
      setBusinessCount(businesses.length);
      
      // Test reviews endpoint
      const reviews = await YelpApiService.getReviews({ skip: 0, limit: 5 });
      setReviewCount(reviews.length);
      
      setApiStatus('✅ API Connection Successful!');
    } catch (err: any) {
      const errorMsg = err.response?.data?.detail || err.message || 'Unknown error';
      setError(`❌ API Error: ${errorMsg}`);
      setApiStatus('Failed');
      console.error('API Test Error:', err);
    }
  };

  return (
    <div style={{ padding: '20px', border: '1px solid #ccc', margin: '20px', borderRadius: '8px' }}>
      <h2>🔍 API Debug Test</h2>
      <div><strong>Status:</strong> {apiStatus}</div>
      <div><strong>API URL:</strong> http://192.168.0.9:8000</div>
      <div><strong>Businesses Found:</strong> {businessCount}</div>
      <div><strong>Reviews Found:</strong> {reviewCount}</div>
      {error && <div style={{ color: 'red' }}><strong>Error:</strong> {error}</div>}
      <button onClick={testApi} style={{ marginTop: '10px', padding: '5px 15px' }}>
        🔄 Retry Test
      </button>
    </div>
  );
};

export default ApiTest;
