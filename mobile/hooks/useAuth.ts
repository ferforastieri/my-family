import { useState, useEffect } from 'react';
import authService, { User, AuthState } from '../api/auth/authService';

export function useAuth() {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    // Verificar usuário atual
    const currentUser = authService.getCurrentUser();
    setAuthState(prev => ({
      ...prev,
      user: currentUser,
      loading: false,
    }));

    // Listener para mudanças de autenticação
    const unsubscribe = authService.onAuthStateChanged((user) => {
      setAuthState({
        user,
        loading: false,
        error: null,
      });
    });

    return unsubscribe;
  }, []);

  const signIn = async (email: string, password: string) => {
    setAuthState(prev => ({ ...prev, loading: true, error: null }));
    try {
      const user = await authService.signInWithEmail(email, password);
      setAuthState({ user, loading: false, error: null });
      return { success: true, user };
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message
      }));
      return { success: false, error: error.message };
    }
  };

  const signUp = async (email: string, password: string, displayName: string) => {
    setAuthState(prev => ({ ...prev, loading: true, error: null }));
    try {
      const user = await authService.signUpWithEmail(email, password, displayName);
      setAuthState({ user, loading: false, error: null });
      return { success: true, user };
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message
      }));
      return { success: false, error: error.message };
    }
  };

  const signOut = async () => {
    setAuthState(prev => ({ ...prev, loading: true, error: null }));
    try {
      await authService.signOut();
      setAuthState({ user: null, loading: false, error: null });
      return { success: true };
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message
      }));
      return { success: false, error: error.message };
    }
  };

  const resetPassword = async (email: string) => {
    setAuthState(prev => ({ ...prev, loading: true, error: null }));
    try {
      await authService.resetPassword(email);
      setAuthState(prev => ({ ...prev, loading: false, error: null }));
      return { success: true };
    } catch (error: any) {
      setAuthState(prev => ({
        ...prev,
        loading: false,
        error: error.message
      }));
      return { success: false, error: error.message };
    }
  };

  const clearError = () => {
    setAuthState(prev => ({ ...prev, error: null }));
  };

  return {
    user: authState.user,
    loading: authState.loading,
    error: authState.error,
    signIn,
    signUp,
    signOut,
    resetPassword,
    clearError,
    isAuthenticated: !!authState.user,
  };
} 