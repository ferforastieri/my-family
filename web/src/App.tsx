import { BrowserRouter } from 'react-router-dom';
import { AppRoutes } from './routes';
import Navigation from './components/common/Navigation';
import { AuthProvider } from './contexts/AuthContext';
import { ToastProvider } from './components/ui/feedback';
import './styles/flower.css';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ToastProvider>
          <Navigation />
          <main className="min-h-screen w-full">
            <AppRoutes />
          </main>
        </ToastProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
