import { Routes, Route } from 'react-router-dom';
import Home from '../pages/Home';
import Messages from '../pages/Messages';
import LoveLetter from '../pages/LoveLetter';
import FlowerForWife from '../pages/FlowerForWife';
import QuizDoAmor from '../pages/QuizDoAmor';

export const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/mensagens" element={<Messages />} />
      <Route path="/carta-de-amor" element={<LoveLetter />} />
      <Route path="/flor-para-esposa" element={<FlowerForWife />} />
      <Route path="/quiz-do-amor" element={<QuizDoAmor />} />
    </Routes>
  );
}; 