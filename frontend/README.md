# Yelp Data Explorer Frontend

A React TypeScript frontend for the Yelp Data FastAPI backend.

## Features

- **Business Explorer**: Browse businesses with filtering by city and star rating
- **Review Browser**: View reviews with pagination and engagement metrics
- **Responsive Design**: Works on desktop and mobile devices
- **Real-time Data**: Connected to your FastAPI backend

## Setup

1. **Install dependencies:**
```bash
cd frontend
npm install
```

2. **Configure API URL (optional):**
Create a `.env` file in the frontend directory:
```
REACT_APP_API_URL=http://192.168.0.123:8000
```

3. **Start the development server:**
```bash
npm start
```

The app will open at `http://localhost:3000`

## Available Scripts

- `npm start` - Runs the app in development mode
- `npm run build` - Builds the app for production
- `npm test` - Runs the test suite
- `npm run eject` - Ejects from Create React App (one-way operation)

## Project Structure

```
frontend/
├── public/
│   └── index.html          # HTML template
├── src/
│   ├── components/         # React components
│   │   ├── BusinessList.tsx
│   │   └── ReviewList.tsx
│   ├── services/           # API service layer
│   │   └── api.ts
│   ├── types/              # TypeScript type definitions
│   │   └── api.ts
│   ├── App.tsx             # Main app component
│   ├── App.css             # App styles
│   ├── index.tsx           # App entry point
│   └── index.css           # Global styles
├── package.json            # Dependencies and scripts
└── tsconfig.json           # TypeScript configuration
```

## API Integration

The frontend connects to your FastAPI backend at `http://192.168.0.123:8000` by default. It uses:

- **Axios** for HTTP requests
- **TypeScript interfaces** matching your API schemas
- **Error handling** for network issues
- **Loading states** for better UX

## Components

### BusinessList
- Displays businesses in a responsive grid
- Search by city or minimum star rating
- Pagination with "Load More" functionality
- Shows business details, ratings, and categories

### ReviewList  
- Shows reviews with star ratings and engagement metrics
- Supports filtering by business or user
- Displays review text with truncation
- Shows useful/funny/cool vote counts

## Styling

- **CSS Grid & Flexbox** for responsive layouts
- **Gradient backgrounds** and modern design
- **Hover effects** and smooth transitions
- **Mobile-first** responsive design

## Development

To add new features:

1. Define TypeScript interfaces in `src/types/api.ts`
2. Add API methods in `src/services/api.ts`  
3. Create React components in `src/components/`
4. Add routing if needed
5. Style with CSS in component files or `App.css`
