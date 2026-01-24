# Comprehensive Testing Guide

This document describes the test suite for the FastAPI Yelp-Postgres application, covering both backend and frontend.

## Table of Contents

1. [Backend Testing](#backend-testing)
2. [Frontend Testing](#frontend-testing)
3. [Running Tests](#running-tests)
4. [Coverage Reports](#coverage-reports)
5. [Writing New Tests](#writing-new-tests)

---

## Backend Testing

### Overview

The backend test suite uses **pytest** with coverage tracking. Tests are organized into three categories:

- **Unit Tests**: Test individual CRUD operations
- **Integration Tests**: Test API endpoints
- **E2E Tests**: Test complete user workflows

### Test Structure

```
tests/
├── conftest.py              # Shared fixtures (database, client, sample data)
├── unit/
│   ├── crud/
│   │   └── test_business_crud.py   # CRUD operation tests
│   ├── schemas/
│   └── models/
├── integration/
│   └── test_api_endpoints.py        # API endpoint tests
└── e2e/
    └── test_workflows.py            # End-to-end workflow tests
```

### Key Fixtures

Located in `conftest.py`:

- **`db`**: Fresh in-memory SQLite database for each test
- **`client`**: FastAPI TestClient with dependency injection
- **`sample_business`**: Pre-created Business record
- **`sample_user`**: Pre-created User record
- **`sample_review`**: Pre-created Review record
- **`sample_tip`**: Pre-created Tip record
- **`sample_checkin`**: Pre-created Checkin record

### Example Unit Test

```python
def test_get_business_by_id(db: Session, sample_business):
    """Test retrieving a specific business"""
    result = crud.get_business(db, business_id="biz_001")
    assert result is not None
    assert result.business_id == "biz_001"
```

### Example Integration Test

```python
def test_get_business_endpoint(client, sample_business):
    """Test GET /businesses/{business_id}"""
    response = client.get("/businesses/biz_001")
    assert response.status_code == 200
    assert response.json()["name"] == "Test Restaurant"
```

### Example E2E Test

```python
def test_discover_restaurant_workflow(client, db):
    """Test: User discovers a restaurant, views reviews, reads tips"""
    # 1. User searches by city
    response = client.get("/businesses/city/Portland")
    assert response.status_code == 200
    
    # 2. User views restaurant details
    rest_id = response.json()[0]["business_id"]
    response = client.get(f"/businesses/{rest_id}")
    assert response.status_code == 200
```

### Test Coverage

Current coverage targets:

- **CRUD Operations**: All business, review, user, tip, and checkin operations
- **API Endpoints**: All routes with valid and invalid inputs
- **Pagination**: Skip/limit parameters
- **Filtering**: City, state, stars, name searches
- **Error Handling**: 404 not found, invalid parameters

---

## Frontend Testing

### Overview

The frontend test suite uses **Jest** and **React Testing Library** with MSW (Mock Service Worker) for API mocking.

### Test Structure

```
frontend/src/__tests__/
├── setupTests.ts            # Jest configuration & MSW setup
├── mocks/
│   └── handlers.ts          # MSW API mock handlers
├── components/
│   ├── BusinessList.test.tsx
│   ├── ReviewList.test.tsx
│   ├── UserList.test.tsx
│   ├── TipList.test.tsx
│   └── ...
└── services/
    └── api.test.ts          # API service tests
```

### Mock Service Worker (MSW)

MSW intercepts network requests and returns mock responses. Handlers are defined in `frontend/src/__tests__/mocks/handlers.ts`.

**Mock Data**:
- 2 sample businesses
- 2 sample users
- 1 sample review

**Supported Endpoints**:
- `GET /businesses/`
- `GET /businesses/:id`
- `GET /businesses/city/:city`
- `GET /businesses/stars/:minStars`
- `GET /reviews/`
- `GET /reviews/:id`
- `GET /reviews/business/:businessId`
- `GET /reviews/user/:userId`
- `GET /users/`
- `GET /users/:id`

### Example Component Test

```typescript
describe('BusinessList Component', () => {
  test('fetches and displays businesses', async () => {
    render(<BrowserRouter><BusinessList /></BrowserRouter>);
    
    await waitFor(() => {
      expect(screen.getByText('Test Restaurant')).toBeInTheDocument();
    });
  });
});
```

### Example Service Test

```typescript
describe('API Service', () => {
  test('fetches businesses successfully', async () => {
    const businesses = await apiClient.getBusinesses();
    expect(businesses).toHaveLength(2);
  });
});
```

### Component Test Coverage

- **Rendering**: Components render without errors
- **Data Fetching**: Mock API calls return expected data
- **Display**: Data is displayed correctly
- **Pagination**: Pagination controls work as expected
- **Details**: Business/user/review details display correctly

---

## Running Tests

### Backend Tests

Install dependencies:

```bash
pip install -e ".[test]"
```

Run all backend tests:

```bash
pytest tests/
```

Run specific test suites:

```bash
# Unit tests only
pytest tests/unit/

# Integration tests only
pytest tests/integration/

# E2E tests only
pytest tests/e2e/

# Specific test file
pytest tests/unit/crud/test_business_crud.py

# Specific test class
pytest tests/unit/crud/test_business_crud.py::TestBusinessCRUD

# Specific test
pytest tests/unit/crud/test_business_crud.py::TestBusinessCRUD::test_get_business_by_id
```

Run with verbose output:

```bash
pytest tests/ -v
```

Run with print statements visible:

```bash
pytest tests/ -s
```

### Frontend Tests

Install dependencies:

```bash
cd frontend
npm install
```

Run all frontend tests:

```bash
npm test
```

Run in watch mode:

```bash
npm test -- --watch
```

Run specific test file:

```bash
npm test -- BusinessList.test.tsx
```

Run with coverage:

```bash
npm test -- --coverage
```

---

## Coverage Reports

### Backend Coverage

Generate coverage report:

```bash
pytest tests/ --cov=src --cov-report=html
```

This creates an HTML report in `htmlcov/index.html`.

View coverage summary:

```bash
pytest tests/ --cov=src --cov-report=term-missing
```

### Frontend Coverage

Generate coverage report:

```bash
cd frontend
npm test -- --coverage --watchAll=false
```

Coverage report appears in `frontend/coverage/`.

### Coverage Targets

- **Backend**: 60% minimum code coverage
- **Frontend**: 50% minimum code coverage
- **Critical Paths**: 100% coverage for:
  - All CRUD operations
  - All API endpoints
  - User workflows
  - Error handling

---

## Writing New Tests

### Backend: Adding a Unit Test

1. Create a test file in `tests/unit/crud/` or appropriate subdirectory
2. Import necessary modules:

```python
import sys
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.crud import crud
from src.db import models
```

3. Write test functions:

```python
class TestNewCRUD:
    def test_my_operation(self, db: Session):
        """Test description"""
        # Setup
        obj = models.MyModel(...)
        db.add(obj)
        db.commit()
        
        # Execute
        result = crud.get_my_model(db, id="123")
        
        # Assert
        assert result is not None
        assert result.field == "value"
```

### Backend: Adding an Integration Test

1. Create a test method in `tests/integration/test_api_endpoints.py`

```python
class TestNewEndpoint:
    def test_new_endpoint(self, client, sample_data):
        """Test description"""
        response = client.get("/endpoint/path")
        assert response.status_code == 200
        assert response.json()[0]["field"] == "expected_value"
```

### Frontend: Adding a Component Test

1. Create a test file: `frontend/src/__tests__/components/MyComponent.test.tsx`

```typescript
import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import MyComponent from '../../components/MyComponent';

describe('MyComponent', () => {
  test('renders correctly', async () => {
    render(<BrowserRouter><MyComponent /></BrowserRouter>);
    
    await waitFor(() => {
      expect(screen.getByText('Expected Text')).toBeInTheDocument();
    });
  });
});
```

### Frontend: Adding API Mock Handlers

1. Edit `frontend/src/__tests__/mocks/handlers.ts`
2. Add new handler to the `handlers` array:

```typescript
rest.get(`${API_BASE}/new-endpoint/:id`, (req, res, ctx) => {
  const { id } = req.params;
  return res(ctx.json({ id, data: 'mock data' }));
}),
```

---

## Best Practices

### Backend

- ✅ Use fixtures for common setup (database, sample data)
- ✅ Test happy path and error cases
- ✅ Use descriptive test names
- ✅ Keep tests focused and isolated
- ✅ Mock external dependencies
- ❌ Don't use real database in tests
- ❌ Don't test implementation details
- ❌ Don't create interdependent tests

### Frontend

- ✅ Test user interactions and workflows
- ✅ Use MSW for API mocking
- ✅ Test component rendering and state
- ✅ Use descriptive test names
- ✅ Render components with necessary wrappers (Router, Providers)
- ❌ Don't test library implementation
- ❌ Don't use shallow rendering for complex interactions
- ❌ Don't test CSS styling

### General

- ✅ Run full test suite before committing
- ✅ Maintain >50% overall coverage
- ✅ Keep tests fast and independent
- ✅ Use clear assertions with helpful error messages
- ✅ Update tests when modifying functionality
- ❌ Don't skip or disable tests
- ❌ Don't leave TODO comments in tests

---

## Troubleshooting

### Backend Issues

**Issue**: Tests fail with "database not found"
- **Solution**: Tests use SQLite by default. Ensure no permission issues.

**Issue**: Import errors in tests
- **Solution**: Verify `PYTHONPATH` includes project root. Check `sys.path` in conftest.py.

**Issue**: Fixture not found error
- **Solution**: Ensure `conftest.py` is in the correct directory (tests/). Verify fixture name matches.

### Frontend Issues

**Issue**: "MSW is not handling requests"
- **Solution**: Verify server.listen() is called in setupTests.ts. Check handler paths match API calls.

**Issue**: "Cannot find module" errors
- **Solution**: Check import paths. Verify tsconfig.json paths are correct.

**Issue**: Tests timeout
- **Solution**: Increase timeout: `test('...', async () => {...}, 10000)`. Check for infinite loops or missing mocks.

---

## CI/CD Integration

### Example GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]
jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.13'
      - run: pip install -e ".[test]"
      - run: pytest tests/ --cov=src

  frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: cd frontend && npm install
      - run: cd frontend && npm test -- --coverage --watchAll=false
```

---

## Next Steps

1. **Run the tests**: `pytest tests/` and `npm test`
2. **Review coverage**: `pytest tests/ --cov=src --cov-report=html`
3. **Add more tests**: Following the patterns in existing tests
4. **Integrate with CI**: Set up automated testing in GitHub Actions
5. **Monitor coverage**: Track coverage metrics over time

---

For questions or issues, refer to:
- [pytest documentation](https://docs.pytest.org/)
- [React Testing Library](https://testing-library.com/react)
- [MSW Documentation](https://mswjs.io/)
- [Jest Documentation](https://jestjs.io/)
