# React Patterns

## Component Typing

```typescript
interface Props {
  title: string;
  count?: number;
  onAction: (id: string) => void;
  children: React.ReactNode;
}

export function MyComponent({ title, count = 0, onAction, children }: Props) {
  return (
    <div>
      <h1>{title}</h1>
      <span>{count}</span>
      <button onClick={() => onAction('123')}>Action</button>
      {children}
    </div>
  );
}
```

## Hooks

```typescript
// useState with type
const [user, setUser] = useState<User | null>(null);

// useReducer
type Action = 
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'set'; payload: number };

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'increment': return state + 1;
    case 'decrement': return state - 1;
    case 'set': return action.payload;
  }
}

const [count, dispatch] = useReducer(reducer, 0);
```

## Context

```typescript
interface AuthContextType {
  user: User | null;
  login: (credentials: Credentials) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  
  const login = async (credentials: Credentials) => {
    const user = await api.login(credentials);
    setUser(user);
  };
  
  const logout = () => setUser(null);
  
  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
```

## Custom Hooks

```typescript
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    
    fetch(url, { signal: controller.signal })
      .then(res => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
    
    return () => controller.abort();
  }, [url]);

  return { data, loading, error };
}

// Usage
const { data: users, loading } = useFetch<User[]>('/api/users');
```

## Event Handlers

```typescript
function Form() {
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // ...
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    console.log(e.target.value);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input onChange={handleChange} />
    </form>
  );
}
```
