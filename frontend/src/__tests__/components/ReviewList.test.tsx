import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import ReviewList from '../../components/ReviewList';

const renderWithRouter = (component: React.ReactElement) => {
  return render(<BrowserRouter>{component}</BrowserRouter>);
};

describe('ReviewList Component', () => {
  test('renders loading state initially', () => {
    renderWithRouter(<ReviewList />);
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });

  test('fetches and displays reviews', async () => {
    renderWithRouter(<ReviewList />);

    await waitFor(() => {
      expect(screen.getByText(/review/i)).toBeInTheDocument();
    });
  });

  test('displays review details correctly', async () => {
    renderWithRouter(<ReviewList />);

    await waitFor(() => {
      expect(screen.getByText('Great food and service!')).toBeInTheDocument();
    });
  });

  test('displays reviewer information', async () => {
    renderWithRouter(<ReviewList />);

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
  });

  test('displays review rating', async () => {
    renderWithRouter(<ReviewList />);

    await waitFor(() => {
      expect(screen.getByText(/5/)).toBeInTheDocument();
    });
  });

  test('displays business name in review', async () => {
    renderWithRouter(<ReviewList />);

    await waitFor(() => {
      expect(screen.getByText('Test Restaurant')).toBeInTheDocument();
    });
  });

  test('displays review date', async () => {
    renderWithRouter(<ReviewList />);

    await waitFor(() => {
      expect(screen.getByText(/2023/)).toBeInTheDocument();
    });
  });
});
