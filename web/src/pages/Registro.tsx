import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../components/ui/feedback';

export default function Registro() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { register } = useAuth();
  const { showToast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await register(email, password, name || undefined);
      showToast({ title: 'Conta criada!', variant: 'success', duration: 2000 });
      navigate('/', { replace: true });
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Erro ao cadastrar';
      setError(msg);
      showToast({ title: 'Erro ao cadastrar', description: msg, variant: 'error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md bg-card p-8 rounded-2xl shadow-lg border border-border"
      >
        <h1 className="text-3xl font-[Pacifico] text-primary text-center mb-8">Criar conta</h1>
        {error && <p className="text-center text-destructive text-sm mb-4">{error}</p>}
        <input
          type="text"
          placeholder="Nome (opcional)"
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="w-full px-4 py-3 mb-4 border-2 border-input rounded-lg text-base bg-background text-foreground focus:outline-none focus:border-primary"
        />
        <input
          type="email"
          placeholder="E-mail"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="w-full px-4 py-3 mb-4 border-2 border-input rounded-lg text-base bg-background text-foreground focus:outline-none focus:border-primary"
        />
        <input
          type="password"
          placeholder="Senha (mín. 6 caracteres)"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          minLength={6}
          className="w-full px-4 py-3 mb-4 border-2 border-input rounded-lg text-base bg-background text-foreground focus:outline-none focus:border-primary"
        />
        <button
          type="submit"
          disabled={loading}
          className="w-full py-4 bg-primary text-primary-foreground rounded-lg text-lg font-medium hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
        >
          {loading ? 'Cadastrando...' : 'Registrar'}
        </button>
        <div className="mt-5 text-center">
          <Link to="/login" className="text-primary text-sm hover:underline">
            Já tenho conta – Entrar
          </Link>
        </div>
      </form>
    </div>
  );
}
