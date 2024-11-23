import { Routes, Route } from 'react-router-dom';
import Home from '../pages/Home';
import Login from '../pages/Login';
import Galeria from '../pages/Galeria';
import Messages from '../pages/Messages';
import LoveLetter from '../pages/LoveLetter';
import FlowerForWife from '../pages/FlowerForWife';
import QuizDoAmor from '../pages/QuizDoAmor';
import Painel from '../pages/Painel';
import PrivateRoute from '../components/PrivateRoute';

export const AppRoutes = () => {
  return (
    <Routes>
      {/* Rotas Públicas */}
      <Route path="/" element={<Home />} />
      <Route path="/login" element={<Login />} />
      <Route path="/mensagens" element={<Messages />} />
      <Route path="/carta-de-amor" element={<LoveLetter />} />
      <Route path="/flor-para-esposa" element={<FlowerForWife />} />
      <Route path="/quiz-do-amor" element={<QuizDoAmor />} />

      {/* Rotas Protegidas */}
      <Route
        path="/galeria"
        element={
          <PrivateRoute>
            <Galeria />
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
    </Routes>
  );
}; 