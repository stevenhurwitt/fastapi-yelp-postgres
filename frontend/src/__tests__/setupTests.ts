import '@testing-library/jest-dom';
import { server } from './mocks/handlers';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
