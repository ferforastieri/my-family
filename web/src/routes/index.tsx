import { Routes, Route } from 'react-router-dom';
import Home from '../pages/Home';
import Login from '../pages/Login';
import Registro from '../pages/Registro';
import EsqueciSenha from '../pages/EsqueciSenha';
import Galeria from '../pages/Galeria';
import Messages from '../pages/Messages';
import FlowerForWife from '../pages/FlowerForWife';
import QuizDoAmor from '../pages/QuizDoAmor';
import Painel from '../pages/Painel';
import Perfil from '../pages/Perfil';
import Admin from '../pages/Admin';
import PrivateRoute from '../components/PrivateRoute';
import AdminRoute from '../components/AdminRoute';
import NossaHistoria from '../pages/NossaHistoria';
import LoveLetter from '../pages/LoveLetter';
import Playlist from '../pages/Playlist';
import Jogos from '../pages/Jogos';
import CacaPalavras from '../pages/CacaPalavras';

export const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/login" element={<Login />} />
      <Route path="/registro" element={<Registro />} />
      <Route path="/esqueci-senha" element={<EsqueciSenha />} />
      <Route path="/nossa-historia" element={<NossaHistoria />} />
      <Route path="/mensagens" element={<Messages />} />
      <Route path="/carta-de-amor" element={<LoveLetter />} />  
      <Route path="/playlist" element={<Playlist />} />
      <Route path="/flor-para-esposa" element={<FlowerForWife />} />
      <Route path="/jogos" element={<Jogos />} />
      <Route path="/quiz-do-amor" element={<QuizDoAmor />} />
      <Route path="/caca-palavras" element={<CacaPalavras />} />

      <Route
        path="/galeria"
        element={
          <PrivateRoute>
            <Galeria />
          </PrivateRoute>
        }
      />
      <Route
        path="/perfil"
        element={
          <PrivateRoute>
            <Perfil />
          </PrivateRoute>
        }
      />
      <Route
        path="/painel"
        element={
          <PrivateRoute>
            <Painel />
          </PrivateRoute>
        }
      />
      <Route
        path="/admin"
        element={
          <AdminRoute>
            <Admin />
          </AdminRoute>
        }
      />
    </Routes>
  );
}; 