import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { apiUrl } from '../config/env';
import { useToast } from '../components/ui/feedback';

type Step = 'request' | 'reset';

export default function EsqueciSenha() {
  const [step, setStep] = useState<Step>('request');
  const [email, setEmail] = useState('');
  const [token, setToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const navigate = useNavigate();
  const { showToast } = useToast();

  const handleRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});
    setLoading(true);
    try {
      const res = await fetch(`${apiUrl}/auth/forgot-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Erro ao solicitar');
      showToast({ title: data.message || 'Se o email existir, você receberá um token. Verifique sua caixa de entrada e spam.', variant: 'success' });
      setStep('reset');
    } catch (err) {
      showToast({ title: err instanceof Error ? err.message : 'Erro ao solicitar recuperação', variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleReset = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});
    if (!token) {
      setErrors((e) => ({ ...e, token: 'Token é obrigatório' }));
      return;
    }
    if (newPassword.length < 8) {
      setErrors((e) => ({ ...e, newPassword: 'A senha deve ter pelo menos 8 caracteres' }));
      return;
    }
    if (newPassword !== confirmPassword) {
      setErrors((e) => ({ ...e, confirmPassword: 'As senhas não coincidem' }));
      return;
    }
    setLoading(true);
    try {
      const res = await fetch(`${apiUrl}/auth/reset-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token, newPassword }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Erro ao redefinir');
      showToast({ title: 'Senha redefinida com sucesso!', variant: 'success' });
      navigate('/login', { replace: true });
    } catch (err) {
      showToast({ title: err instanceof Error ? err.message : 'Erro ao redefinir senha', variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <div className="w-full max-w-md bg-card p-8 rounded-2xl shadow-lg">
        <h1 className="text-2xl font-[Pacifico] text-love-primary text-center mb-2">Recuperar senha</h1>
        <p className="text-muted-foreground text-sm text-center mb-6">
          {step === 'request' ? 'Digite seu email para receber um token de recuperação' : 'Informe o token e a nova senha'}
        </p>

        {step === 'request' ? (
          <form onSubmit={handleRequest} className="space-y-4">
            <input
              type="email"
              placeholder="seu@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-4 py-3 border-2 border-[var(--love-primary-light)] rounded-xl focus:outline-none focus:border-[var(--love-primary)] bg-background"
            />
            <p className="text-muted-foreground text-xs text-center">Se o email existir, você receberá um token por email. Verifique a caixa de entrada e o spam.</p>
            <button type="submit" disabled={loading} className="w-full py-3 rounded-xl bg-[var(--love-primary)] text-white font-medium hover:bg-[var(--love-primary-dark)] disabled:opacity-70">
              {loading ? 'Enviando...' : 'Enviar token'}
            </button>
            <Link to="/login" className="block text-center text-sm text-love-primary hover:underline">Voltar ao login</Link>
          </form>
        ) : (
          <form onSubmit={handleReset} className="space-y-4">
            <input
              type="text"
              placeholder="Token de recuperação"
              value={token}
              onChange={(e) => setToken(e.target.value)}
              className="w-full px-4 py-3 border-2 border-[var(--love-primary-light)] rounded-xl focus:outline-none focus:border-[var(--love-primary)] bg-background"
            />
            {errors.token && <p className="text-sm text-destructive">{errors.token}</p>}
            <input
              type="password"
              placeholder="Nova senha (mín. 8 caracteres)"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              minLength={8}
              className="w-full px-4 py-3 border-2 border-[var(--love-primary-light)] rounded-xl focus:outline-none focus:border-[var(--love-primary)] bg-background"
            />
            {errors.newPassword && <p className="text-sm text-destructive">{errors.newPassword}</p>}
            <input
              type="password"
              placeholder="Confirmar senha"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full px-4 py-3 border-2 border-[var(--love-primary-light)] rounded-xl focus:outline-none focus:border-[var(--love-primary)] bg-background"
            />
            {errors.confirmPassword && <p className="text-sm text-destructive">{errors.confirmPassword}</p>}
            <button type="submit" disabled={loading} className="w-full py-3 rounded-xl bg-[var(--love-primary)] text-white font-medium hover:bg-[var(--love-primary-dark)] disabled:opacity-70">
              {loading ? 'Redefinindo...' : 'Redefinir senha'}
            </button>
            <button type="button" onClick={() => setStep('request')} className="w-full py-2 text-sm text-love-primary hover:underline">
              Voltar
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
