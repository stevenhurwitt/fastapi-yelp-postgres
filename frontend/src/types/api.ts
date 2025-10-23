export interface Business {
  business_id: string;
  name?: string;
  address?: string;
  city?: string;
  state?: string;
  postal_code?: string;
  latitude?: number;
  longitude?: number;
  stars?: number;
  review_count?: number;
  is_open?: number;
  attributes?: string;
  categories?: string;
  hours?: string;
}

export interface Review {
  review_id: string;
  user_id?: string;
  business_id?: string;
  stars?: number;
  useful?: number;
  funny?: number;
  cool?: number;
  text?: string;
  date?: string;
  year?: number;
  month?: number;
  user_name?: string;    // Added user name
  business_name?: string; // Added business name
}

export interface User {
  user_id: string;
  name?: string;
  review_count?: number;
  yelping_since?: string;
  friends?: string;
  useful?: number;
  funny?: number;
  cool?: number;
  fans?: number;
  elite?: string;
  average_stars?: number;
  compliment_hot?: number;
  compliment_more?: number;
  compliment_profile?: number;
  compliment_cute?: number;
  compliment_list?: number;
  compliment_note?: number;
  compliment_plain?: number;
  compliment_cool?: number;
  compliment_funny?: number;
  compliment_writer?: number;
  compliment_photos?: number;
}

export interface Tip {
  user_id: string;
  business_id: string;
  text?: string;
  date?: string;
  compliment_count?: number;
  year?: number;
}

export interface Checkin {
  business_id: string;
  date: string;
}

export interface ApiResponse<T> {
  data: T[];
  total?: number;
}

export interface SearchFilters {
  skip?: number;
  limit?: number;
  city?: string;
  min_stars?: number;
}
