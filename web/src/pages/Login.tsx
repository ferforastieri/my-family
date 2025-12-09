import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import styled from 'styled-components';

const LoginContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
`;

const LoginForm = styled.form`
  background: rgba(255, 255, 255, 0.95);
  padding: 2rem;
  border-radius: 15px;
  box-shadow: 0 4px 15px rgba(255, 105, 180, 0.2);
  width: 100%;
  max-width: 400px;
`;

const Title = styled.h1`
  color: #ff69b4;
  font-family: 'Pacifico', cursive;
  font-size: 2.5rem;
  text-align: center;
  margin-bottom: 2rem;
`;

const Input = styled.input`
  width: 100%;
  padding: 0.8rem;
  margin-bottom: 1rem;
  border: 2px solid #ffe6f2;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s ease;

  &:focus {
    outline: none;
    border-color: #ff69b4;
  }
`;

const Button = styled.button`
  width: 100%;
  padding: 1rem;
  background: #ff69b4;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1.1rem;
  font-family: 'Dancing Script', cursive;
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background: #ff1493;
    transform: translateY(-2px);
  }

  &:disabled {
    background: #ffb6c1;
    cursor: not-allowed;
    transform: none;
  }
`;

const ErrorMessage = styled.p`
  color: #ff1493;
  text-align: center;
  margin-bottom: 1rem;
  font-size: 0.9rem;
`;

const Login = () => {
  const [senha, setSenha] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Aqui você pode adicionar sua lógica de validação
      if (senha === import.meta.env.VITE_LOGIN_PASSWORD) {
        localStorage.setItem('isAuthenticated', 'true');
        navigate('/');
      } else {
        setError('Senha incorreta');
      }
    } catch (error) {
      setError('Erro ao fazer login');
    } finally {
      setLoading(false);
    }
  };

  return (
    <LoginContainer>
      <LoginForm onSubmit={handleSubmit}>
        <Title>Área Restrita</Title>
        {error && <ErrorMessage>{error}</ErrorMessage>}
        <Input
          type="password"
          placeholder="Digite a senha..."
          value={senha}
          onChange={(e) => setSenha(e.target.value)}
          required
        />
        <Button type="submit" disabled={loading}>
          {loading ? 'Entrando...' : 'Entrar'}
        </Button>
      </LoginForm>
    </LoginContainer>
  );
};

export default Login; 