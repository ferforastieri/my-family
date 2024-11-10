import { BrowserRouter } from 'react-router-dom';
import { GlobalStyle } from './assets/styles/global';
import { AppRoutes } from './routes';
import Navigation from './components/common/Navigation';
import './styles/flower.css';

function App() {
  return (
    <BrowserRouter>
      <GlobalStyle />
      <Navigation />
      <AppRoutes />
    </BrowserRouter>
  );
}

export default App;
