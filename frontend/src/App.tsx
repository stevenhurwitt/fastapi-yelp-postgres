import React, { useState } from 'react';
import BusinessList from './components/BusinessList';
import ReviewList from './components/ReviewList';
import UserList from './components/UserList';
import ApiTest from './components/ApiTest';
import './App.css';

type TabType = 'businesses' | 'reviews' | 'users' | 'tips' | 'debug';

function App() {
  const [activeTab, setActiveTab] = useState<TabType>('debug');

  return (
    <div className="App">
      <header className="App-header">
        <h1>🌟 Yelp Data Explorer</h1>
        <nav className="nav-tabs">
          <button 
            className={activeTab === 'debug' ? 'active' : ''}
            onClick={() => setActiveTab('debug')}
          >
            🔍 Debug
          </button>
          <button 
            className={activeTab === 'businesses' ? 'active' : ''}
            onClick={() => setActiveTab('businesses')}
          >
            Businesses
          </button>
          <button 
            className={activeTab === 'reviews' ? 'active' : ''}
            onClick={() => setActiveTab('reviews')}
          >
            Reviews
          </button>
          <button 
            className={activeTab === 'users' ? 'active' : ''}
            onClick={() => setActiveTab('users')}
          >
            Users
          </button>
          <button 
            className={activeTab === 'tips' ? 'active' : ''}
            onClick={() => setActiveTab('tips')}
          >
            Tips
          </button>
        </nav>
      </header>

      <main className="App-main">
        {activeTab === 'debug' && <ApiTest />}
        {activeTab === 'businesses' && <BusinessList />}
        {activeTab === 'reviews' && <ReviewList />}
        {activeTab === 'users' && <UserList />}
        {activeTab === 'tips' && (
          <div className="coming-soon">
            <h2>Tips</h2>
            <p>Tips explorer coming soon...</p>
          </div>
        )}
      </main>

      <footer className="App-footer">
        <p>Powered by FastAPI + PostgreSQL</p>
      </footer>
    </div>
  );
}

export default App;
