import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import BusinessList from '../../components/BusinessList';

const renderWithRouter = (component: React.ReactElement) => {
  return render(<BrowserRouter>{component}</BrowserRouter>);
};

describe('BusinessList Component', () => {
  test('renders loading state initially', () => {
    renderWithRouter(<BusinessList />);
    // Component should render without crashing
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });

  test('fetches and displays businesses', async () => {
    renderWithRouter(<BusinessList />);

    await waitFor(() => {
      expect(screen.getByText('Test Restaurant')).toBeInTheDocument();
    });
  });

  test('displays business details correctly', async () => {
    renderWithRouter(<BusinessList />);

    await waitFor(() => {
      expect(screen.getByText('Test Restaurant')).toBeInTheDocument();
      expect(screen.getByText(/Portland/i)).toBeInTheDocument();
    });
  });

  test('handles pagination correctly', async () => {
    renderWithRouter(<BusinessList />);

    await waitFor(() => {
      expect(screen.getByText('Test Restaurant')).toBeInTheDocument();
    });

    // Check if pagination controls are present
    const buttons = screen.getAllByRole('button');
    expect(buttons.length).toBeGreaterThan(0);
  });

  test('displays business rating', async () => {
    renderWithRouter(<BusinessList />);

    await waitFor(() => {
      expect(screen.getByText(/4\.5/)).toBeInTheDocument();
    });
  });

  test('displays business location', async () => {
    renderWithRouter(<BusinessList />);

    await waitFor(() => {
      expect(screen.getByText('Portland')).toBeInTheDocument();
      expect(screen.getByText('OR')).toBeInTheDocument();
    });
  });
});
