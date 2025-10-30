import axios from 'axios';
import { Business, Review, User, Tip, Checkin, SearchFilters } from '../types/api';

// Environment-aware API URL configuration
const getApiBaseUrl = () => {
  // Check for environment variable first
  if (process.env.REACT_APP_API_URL) {
    // If it's the placeholder AWS URL, use local instead
    if (process.env.REACT_APP_API_URL.includes('your-load-balancer-dns')) {
      console.warn('⚠️ Using placeholder AWS URL, falling back to local Raspberry Pi');
      return 'https://192.168.0.9';
    }
    return process.env.REACT_APP_API_URL;
  }
  
  // Use nginx reverse proxy - same origin, no CORS issues
  return 'https://192.168.0.9';
};

// HTTP fallback URL for SSL issues
const getHttpFallbackUrl = () => {
  return 'http://192.168.0.9:8000';
};

const API_BASE_URL = getApiBaseUrl();

// Debug logging
console.log('🌐 API Configuration:');
console.log('   REACT_APP_API_URL:', process.env.REACT_APP_API_URL);
console.log('   Final API_BASE_URL:', API_BASE_URL);

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 seconds - API responds in < 1 second
  // Handle self-signed certificates in development
  httpsAgent: process.env.NODE_ENV === 'development' ? undefined : undefined,
});

// Add request interceptor for debugging
api.interceptors.request.use(
  (config) => {
    console.log('🚀 Making API request to:', config.url);
    console.log('🔗 Full URL:', `${config.baseURL}${config.url}`);
    return config;
  },
  (error) => {
    console.error('❌ Request error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor for debugging
api.interceptors.response.use(
  (response) => {
    const itemCount = Array.isArray(response.data) ? response.data.length : 'N/A';
    console.log('✅ API response:', response.status, itemCount, 'items');
    if (response.config.url?.includes('reviews') && typeof itemCount === 'number' && itemCount > 0) {
      console.log('🎉 Reviews loaded successfully!', itemCount, 'reviews received');
    }
    return response;
  },
  (error) => {
    console.error('❌ API Error:', error.message);
    
    // Enhanced error logging for debugging
    if (error.code === 'ECONNABORTED') {
      console.error('⏰ Request timed out after', error.config?.timeout, 'ms');
      console.error('🔍 URL attempted:', error.config?.url);
      console.error('💡 Try refreshing browser or checking network connection');
    }
    
    if (error.code === 'ERR_NETWORK') {
      console.error('🌐 Network error - Check if API server is running');
      console.error('🔍 API URL:', API_BASE_URL);
      console.error('💡 Ensure SSL certificate is accepted');
    }
    
    if (error.code === 'ERR_CERT_AUTHORITY_INVALID') {
      console.error('🔒 SSL Certificate error - Self-signed certificate issue');
      console.error('💡 Navigate to', API_BASE_URL, 'and accept certificate');
    }
    
    if (error.response) {
      console.error('📊 Error details:', {
        status: error.response.status,
        statusText: error.response.statusText,
        data: error.response.data,
        url: error.response.config?.url
      });
    } else if (error.request) {
      console.error('📡 Request made but no response received');
      console.error('🔍 Request details:', {
        method: error.config?.method,
        url: error.config?.url,
        baseURL: error.config?.baseURL,
        timeout: error.config?.timeout
      });
    }
    
    return Promise.reject(error);
  }
);

export class YelpApiService {
  // Health check and connectivity test
  static async testConnectivity(): Promise<{ status: string; url: string }> {
    try {
      const response = await api.get('/health');
      return { status: 'success', url: API_BASE_URL };
    } catch (error) {
      console.error('Primary API endpoint failed, testing HTTP fallback...');
      try {
        const httpResponse = await axios.get(`${getHttpFallbackUrl()}/health`, { timeout: 5000 });
        return { status: 'fallback', url: getHttpFallbackUrl() };
      } catch (fallbackError) {
        throw new Error(`Both HTTPS and HTTP endpoints failed: ${error}`);
      }
    }
  }

  // Business endpoints
  static async getBusinesses(filters?: SearchFilters): Promise<Business[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/businesses/?${params}`);
    return response.data;
  }

  static async getBusiness(businessId: string): Promise<Business> {
    const response = await api.get(`/api/v1/businesses/${businessId}`);
    return response.data;
  }

  static async getBusinessesByCity(city: string, filters?: SearchFilters): Promise<Business[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/businesses/city/${encodeURIComponent(city)}?${params}`);
    return response.data;
  }

  static async getBusinessesByStars(minStars: number, filters?: SearchFilters): Promise<Business[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/businesses/stars/${minStars}?${params}`);
    return response.data;
  }

  static async getBusinessesByState(state: string, filters?: SearchFilters): Promise<Business[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/businesses/state/${encodeURIComponent(state)}?${params}`);
    return response.data;
  }

  static async searchBusinessesByName(name: string, filters?: SearchFilters): Promise<Business[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/businesses/search/${encodeURIComponent(name)}?${params}`);
    return response.data;
  }

  // Review endpoints
  static async getReviews(filters?: SearchFilters): Promise<Review[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/reviews/?${params}`);
    return response.data;
  }

  static async getReview(reviewId: string): Promise<Review> {
    const response = await api.get(`/api/v1/reviews/${reviewId}`);
    return response.data;
  }

  static async getReviewsByBusiness(businessId: string, filters?: SearchFilters): Promise<Review[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/reviews/business/${businessId}?${params}`);
    return response.data;
  }

  static async getReviewsByUser(userId: string, filters?: SearchFilters): Promise<Review[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/reviews/user/${userId}?${params}`);
    return response.data;
  }

  // User endpoints
  static async getUsers(filters?: SearchFilters): Promise<User[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/users/?${params}`);
    return response.data;
  }

  static async getUser(userId: string): Promise<User> {
    const response = await api.get(`/api/v1/users/${userId}`);
    return response.data;
  }

  // Tip endpoints
  static async getTips(filters?: SearchFilters): Promise<Tip[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/tips/?${params}`);
    return response.data;
  }

  static async getTipsByBusiness(businessId: string, filters?: SearchFilters): Promise<Tip[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/tips/business/${businessId}?${params}`);
    return response.data;
  }

  static async getTipsByUser(userId: string, filters?: SearchFilters): Promise<Tip[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/tips/user/${userId}?${params}`);
    return response.data;
  }

  // Checkin endpoints
  static async getCheckins(filters?: SearchFilters): Promise<Checkin[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/checkins/?${params}`);
    return response.data;
  }

  static async getCheckinsByBusiness(businessId: string, filters?: SearchFilters): Promise<Checkin[]> {
    const params = new URLSearchParams();
    if (filters?.skip) params.append('skip', filters.skip.toString());
    if (filters?.limit) params.append('limit', filters.limit.toString());
    
    const response = await api.get(`/api/v1/checkins/business/${businessId}?${params}`);
    return response.data;
  }

  // Health check
  static async healthCheck(): Promise<{ status: string }> {
    const response = await api.get('/health');
    return response.data;
  }
}
