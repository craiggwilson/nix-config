# TypeScript Testing

## Vitest

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('UserService', () => {
  it('should create a user', async () => {
    const service = new UserService();
    
    const user = await service.create({
      name: 'John',
      email: 'john@example.com',
    });
    
    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
  });

  it('should throw on invalid email', async () => {
    const service = new UserService();
    
    await expect(
      service.create({ name: 'John', email: 'invalid' })
    ).rejects.toThrow('Invalid email');
  });
});
```

## Mocking

```typescript
import { vi, Mock } from 'vitest';

// Mock module
vi.mock('./api', () => ({
  fetchUser: vi.fn(),
}));

import { fetchUser } from './api';

it('should fetch user', async () => {
  (fetchUser as Mock).mockResolvedValue({ id: 1, name: 'John' });
  
  const result = await getUser(1);
  
  expect(fetchUser).toHaveBeenCalledWith(1);
  expect(result.name).toBe('John');
});

// Spy on method
const spy = vi.spyOn(console, 'log');
myFunction();
expect(spy).toHaveBeenCalledWith('expected message');
```

## React Testing Library

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

it('should submit form', async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);
  
  await userEvent.type(screen.getByLabelText('Email'), 'test@example.com');
  await userEvent.type(screen.getByLabelText('Password'), 'password');
  await userEvent.click(screen.getByRole('button', { name: 'Login' }));
  
  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password',
    });
  });
});

it('should show error message', async () => {
  render(<LoginForm onSubmit={() => Promise.reject(new Error('Invalid'))} />);
  
  await userEvent.click(screen.getByRole('button', { name: 'Login' }));
  
  expect(await screen.findByText('Invalid')).toBeInTheDocument();
});
```

## Type Testing

```typescript
import { expectTypeOf } from 'vitest';

it('should have correct types', () => {
  const result = myFunction();
  
  expectTypeOf(result).toEqualTypeOf<{ id: string; name: string }>();
  expectTypeOf(result.id).toBeString();
});
```

## Snapshot Testing

```typescript
it('should match snapshot', () => {
  const { container } = render(<UserCard user={mockUser} />);
  expect(container).toMatchSnapshot();
});

// Inline snapshot
it('should format correctly', () => {
  expect(formatUser(mockUser)).toMatchInlineSnapshot(`
    "John Doe <john@example.com>"
  `);
});
```
