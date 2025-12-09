import { BrowserRouter } from 'react-router-dom';
import { AppRoutes } from './routes';
import Navigation from './components/common/Navigation';
import './styles/flower.css';
import { AuthProvider } from './contexts/AuthContext';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Navigation />
        <main className="min-h-screen w-full">
          <AppRoutes />
        </main>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
