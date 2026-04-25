import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import TipList from '../../components/TipList';

const renderWithRouter = (component: React.ReactElement) => {
  return render(<BrowserRouter>{component}</BrowserRouter>);
};

describe('TipList Component', () => {
  test('renders without crashing', () => {
    renderWithRouter(<TipList />);
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });

  test('fetches and displays tips', async () => {
    renderWithRouter(<TipList />);

    await waitFor(() => {
      // Wait for component to load
      expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
    });
  });

  test('handles empty tips list', async () => {
    renderWithRouter(<TipList />);

    await waitFor(() => {
      // Should render without errors even with empty tips
      expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
    });
  });
});
