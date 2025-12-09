import { createContext, useContext, ReactNode, useState, useEffect } from 'react';
import { signIn, signOut, authClient } from '../lib/better-auth';

interface AuthContextType {
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  user: any;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Verificar sessão inicial
    authClient.getSession().then((response) => {
      if (response?.data) {
        setUser(response.data.user ?? null);
      }
      setLoading(false);
    }).catch(() => {
      setLoading(false);
    });
  }, []);

  const handleSignIn = async (email: string, password: string) => {
    await signIn.email({
      email,
      password,
    });
    // Atualizar usuário após login
    const response = await authClient.getSession();
    if (response?.data) {
      setUser(response.data.user ?? null);
    }
  };

  const handleSignOut = async () => {
    await signOut();
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        signIn: handleSignIn,
        signOut: handleSignOut,
        user,
        loading,
      }}
    >
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
