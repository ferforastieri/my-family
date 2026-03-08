import { BrowserRouter } from 'react-router-dom';
import { AppRoutes } from './routes';
import Navigation from './components/common/Navigation';
import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { ToastProvider } from './components/ui/feedback';

function App() {
  return (
    <BrowserRouter>
      <ThemeProvider>
        <AuthProvider>
          <ToastProvider>
            <Navigation />
            <main className="min-h-screen w-full">
              <AppRoutes />
            </main>
          </ToastProvider>
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
}

export default App;
