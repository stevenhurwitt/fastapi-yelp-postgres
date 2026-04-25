import { server } from '../mocks/handlers';
import { rest } from 'msw';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

// Simplified API service for testing
const apiClient = {
  async getBusinesses(skip = 0, limit = 10) {
    const response = await fetch(`${API_BASE}/businesses/?skip=${skip}&limit=${limit}`);
    if (!response.ok) throw new Error('Failed to fetch businesses');
    return response.json();
  },

  async getBusiness(id: string) {
    const response = await fetch(`${API_BASE}/businesses/${id}`);
    if (!response.ok) throw new Error('Business not found');
    return response.json();
  },

  async getReviews(skip = 0, limit = 10) {
    const response = await fetch(`${API_BASE}/reviews/?skip=${skip}&limit=${limit}`);
    if (!response.ok) throw new Error('Failed to fetch reviews');
    return response.json();
  },

  async getUsers(skip = 0, limit = 10) {
    const response = await fetch(`${API_BASE}/users/?skip=${skip}&limit=${limit}`);
    if (!response.ok) throw new Error('Failed to fetch users');
    return response.json();
  },
};

describe('API Service', () => {
  describe('getBusinesses', () => {
    test('fetches businesses successfully', async () => {
      const businesses = await apiClient.getBusinesses();
      expect(businesses).toHaveLength(2);
      expect(businesses[0]).toHaveProperty('business_id');
    });

    test('fetches with pagination', async () => {
      const businesses = await apiClient.getBusinesses(0, 1);
      expect(businesses).toHaveLength(1);
    });

    test('handles fetch error', async () => {
      server.use(
        rest.get(`${API_BASE}/businesses/`, (req, res, ctx) => {
          return res(ctx.status(500));
        })
      );

      await expect(apiClient.getBusinesses()).rejects.toThrow();
    });
  });

  describe('getBusiness', () => {
    test('fetches single business', async () => {
      const business = await apiClient.getBusiness('biz_001');
      expect(business.business_id).toBe('biz_001');
      expect(business.name).toBe('Test Restaurant');
    });

    test('handles not found error', async () => {
      await expect(apiClient.getBusiness('nonexistent')).rejects.toThrow();
    });
  });

  describe('getReviews', () => {
    test('fetches reviews successfully', async () => {
      const reviews = await apiClient.getReviews();
      expect(Array.isArray(reviews)).toBe(true);
    });

    test('fetches with pagination', async () => {
      const reviews = await apiClient.getReviews(0, 5);
      expect(Array.isArray(reviews)).toBe(true);
    });
  });

  describe('getUsers', () => {
    test('fetches users successfully', async () => {
      const users = await apiClient.getUsers();
      expect(users).toHaveLength(2);
      expect(users[0]).toHaveProperty('user_id');
    });

    test('fetches with pagination', async () => {
      const users = await apiClient.getUsers(0, 1);
      expect(users).toHaveLength(1);
    });
  });
});
