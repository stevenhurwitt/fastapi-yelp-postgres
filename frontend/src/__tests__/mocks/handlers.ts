import { setupServer } from 'msw';
import { rest } from 'msw';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

export const mockBusinesses = [
  {
    business_id: 'biz_001',
    name: 'Test Restaurant',
    address: '123 Main St',
    city: 'Portland',
    state: 'OR',
    postal_code: '97201',
    latitude: 45.5152,
    longitude: -122.6784,
    stars: 4.5,
    review_count: 100,
    is_open: 1,
    categories: 'Restaurants,Italian',
  },
  {
    business_id: 'biz_002',
    name: 'Coffee Shop',
    address: '456 Oak Ave',
    city: 'Seattle',
    state: 'WA',
    postal_code: '98101',
    latitude: 47.6062,
    longitude: -122.3321,
    stars: 4.2,
    review_count: 75,
    is_open: 1,
    categories: 'Coffee,Cafes',
  },
];

export const mockUsers = [
  {
    user_id: 'user_001',
    name: 'John Doe',
    review_count: 25,
    yelping_since: '2020-01-01T00:00:00',
    useful: 150,
    funny: 50,
    cool: 30,
    fans: 5,
    average_stars: 4.2,
  },
  {
    user_id: 'user_002',
    name: 'Jane Smith',
    review_count: 45,
    yelping_since: '2019-06-15T00:00:00',
    useful: 300,
    funny: 100,
    cool: 80,
    fans: 15,
    average_stars: 4.5,
  },
];

export const mockReviews = [
  {
    review_id: 'rev_001',
    user_id: 'user_001',
    business_id: 'biz_001',
    stars: 5,
    useful: 10,
    funny: 2,
    cool: 5,
    text: 'Great food and service!',
    date: '2023-06-15T00:00:00',
    year: 2023,
    month: 6,
    user_name: 'John Doe',
    business_name: 'Test Restaurant',
  },
];

export const handlers = [
  // Business endpoints
  rest.get(`${API_BASE}/businesses/`, (req, res, ctx) => {
    const skip = parseInt(req.url.searchParams.get('skip') || '0');
    const limit = parseInt(req.url.searchParams.get('limit') || '10');
    return res(ctx.json(mockBusinesses.slice(skip, skip + limit)));
  }),

  rest.get(`${API_BASE}/businesses/:id`, (req, res, ctx) => {
    const { id } = req.params;
    const business = mockBusinesses.find((b) => b.business_id === id);
    if (!business) {
      return res(ctx.status(404), ctx.json({ detail: 'Business not found' }));
    }
    return res(ctx.json(business));
  }),

  rest.get(`${API_BASE}/businesses/city/:city`, (req, res, ctx) => {
    const { city } = req.params;
    const filtered = mockBusinesses.filter((b) =>
      b.city.toLowerCase().includes(city.toLowerCase())
    );
    return res(ctx.json(filtered));
  }),

  rest.get(`${API_BASE}/businesses/stars/:minStars`, (req, res, ctx) => {
    const { minStars } = req.params;
    const filtered = mockBusinesses.filter((b) => b.stars >= parseFloat(minStars));
    return res(ctx.json(filtered));
  }),

  // Review endpoints
  rest.get(`${API_BASE}/reviews/`, (req, res, ctx) => {
    const skip = parseInt(req.url.searchParams.get('skip') || '0');
    const limit = parseInt(req.url.searchParams.get('limit') || '10');
    return res(ctx.json(mockReviews.slice(skip, skip + limit)));
  }),

  rest.get(`${API_BASE}/reviews/:id`, (req, res, ctx) => {
    const { id } = req.params;
    const review = mockReviews.find((r) => r.review_id === id);
    if (!review) {
      return res(ctx.status(404), ctx.json({ detail: 'Review not found' }));
    }
    return res(ctx.json(review));
  }),

  rest.get(`${API_BASE}/reviews/business/:businessId`, (req, res, ctx) => {
    const { businessId } = req.params;
    const filtered = mockReviews.filter((r) => r.business_id === businessId);
    return res(ctx.json(filtered));
  }),

  rest.get(`${API_BASE}/reviews/user/:userId`, (req, res, ctx) => {
    const { userId } = req.params;
    const filtered = mockReviews.filter((r) => r.user_id === userId);
    return res(ctx.json(filtered));
  }),

  // User endpoints
  rest.get(`${API_BASE}/users/`, (req, res, ctx) => {
    const skip = parseInt(req.url.searchParams.get('skip') || '0');
    const limit = parseInt(req.url.searchParams.get('limit') || '10');
    return res(ctx.json(mockUsers.slice(skip, skip + limit)));
  }),

  rest.get(`${API_BASE}/users/:id`, (req, res, ctx) => {
    const { id } = req.params;
    const user = mockUsers.find((u) => u.user_id === id);
    if (!user) {
      return res(ctx.status(404), ctx.json({ detail: 'User not found' }));
    }
    return res(ctx.json(user));
  }),

  // Tips endpoints
  rest.get(`${API_BASE}/tips/`, (req, res, ctx) => {
    return res(ctx.json([]));
  }),

  // Checkins endpoints
  rest.get(`${API_BASE}/checkins/`, (req, res, ctx) => {
    return res(ctx.json([]));
  }),
];

export const server = setupServer(...handlers);
