import { createContext, useContext, ReactNode, useState, useEffect, useCallback } from 'react';
import { apiUrl } from '../config/env';

export type UserRole = 'admin' | 'wife' | 'child' | 'friend';

interface User {
  id: number;
  email: string;
  name: string | null;
  role: UserRole;
  avatarPath?: string | null;
}

interface AuthContextType {
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  register: (email: string, password: string, name?: string) => Promise<void>;
  setUser: (user: User | null) => void;
  uploadAvatar: (file: File) => Promise<void>;
  user: User | null;
  loading: boolean;
}

const TOKEN_KEY = 'lovepage_token';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchUser = useCallback(async (token: string) => {
    const res = await fetch(`${apiUrl}/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) return null;
    const data = await res.json();
    return data.user as User;
  }, []);

  useEffect(() => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) {
      setLoading(false);
      return;
    }
    fetchUser(token)
      .then((u) => setUser(u))
      .catch(() => { localStorage.removeItem(TOKEN_KEY); })
      .finally(() => setLoading(false));
  }, [fetchUser]);

  const signIn = async (email: string, password: string) => {
    const res = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.message || 'Email ou senha inválidos');
    }
    const data = await res.json();
    localStorage.setItem(TOKEN_KEY, data.access_token);
    setUser(data.user);
  };

  const signOut = async () => {
    localStorage.removeItem(TOKEN_KEY);
    setUser(null);
  };

  const register = async (email: string, password: string, name?: string) => {
    const res = await fetch(`${apiUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, name }),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.message || 'Erro ao cadastrar');
    }
    const data = await res.json();
    localStorage.setItem(TOKEN_KEY, data.access_token);
    setUser(data.user);
  };

  const uploadAvatar = async (file: File) => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) throw new Error('Não autenticado');
    const form = new FormData();
    form.append('file', file);
    const res = await fetch(`${apiUrl}/auth/avatar`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: form,
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.message || 'Erro ao enviar avatar');
    }
    const data = await res.json();
    if (data.user) setUser(data.user);
  };

  return (
    <AuthContext.Provider value={{ signIn, signOut, register, setUser, uploadAvatar, user, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const getToken = () => localStorage.getItem(TOKEN_KEY);
