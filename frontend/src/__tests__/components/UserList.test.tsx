import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import UserList from '../../components/UserList';

const renderWithRouter = (component: React.ReactElement) => {
  return render(<BrowserRouter>{component}</BrowserRouter>);
};

describe('UserList Component', () => {
  test('renders loading state initially', () => {
    renderWithRouter(<UserList />);
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });

  test('fetches and displays users', async () => {
    renderWithRouter(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
  });

  test('displays user details correctly', async () => {
    renderWithRouter(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText(/25/)).toBeInTheDocument(); // review count
    });
  });

  test('displays user review count', async () => {
    renderWithRouter(<UserList />);

    await waitFor(() => {
      expect(screen.getByText(/25/)).toBeInTheDocument();
    });
  });

  test('displays user average stars', async () => {
    renderWithRouter(<UserList />);

    await waitFor(() => {
      expect(screen.getByText(/4\.2/)).toBeInTheDocument();
    });
  });

  test('displays multiple users', async () => {
    renderWithRouter(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
    });
  });

  test('displays user fans count', async () => {
    renderWithRouter(<UserList />);

    await waitFor(() => {
      expect(screen.getByText(/fans/i)).toBeInTheDocument();
    });
  });
});
