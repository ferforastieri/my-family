import { Link } from 'react-router-dom';

export default function EsqueciSenha() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-8 bg-gradient-to-b from-[#fff8fa] to-[#fff0f5]">
      <div className="w-full max-w-md bg-white/95 p-8 rounded-2xl shadow-lg shadow-pink-200/50 text-center">
        <h1 className="text-2xl font-[Pacifico] text-pink-500 mb-4">Esqueci a senha</h1>
        <p className="text-gray-600 text-base mb-6 leading-relaxed">
          Para redefinir sua senha, entre em contato com o administrador do site
          ou use o e-mail de cadastro para recuperação.
        </p>
        <Link to="/login" className="text-pink-500 text-sm hover:underline">
          Voltar ao login
        </Link>
      </div>
    </div>
  );
}
