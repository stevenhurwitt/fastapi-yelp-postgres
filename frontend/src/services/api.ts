import axios from 'axios';
import { Business, Review, User, Tip, Checkin, SearchFilters } from '../types/api';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://192.168.0.123:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export class YelpApiService {
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
