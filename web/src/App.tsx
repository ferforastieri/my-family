import { useState } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { AppRoutes } from './routes';
import Navigation from './components/common/Navigation';
import NotificationPanel from './components/common/NotificationPanel';
import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { NotificationsProvider } from './contexts/NotificationsContext';
import { ToastProvider } from './components/ui/feedback';

export default function App() {
  const [notificationPanelOpen, setNotificationPanelOpen] = useState(false);
  return (
    <BrowserRouter>
      <ThemeProvider>
        <NotificationsProvider>
          <AuthProvider>
            <ToastProvider>
              <Navigation onOpenNotifications={() => setNotificationPanelOpen(true)} />
              <NotificationPanel isOpen={notificationPanelOpen} onClose={() => setNotificationPanelOpen(false)} />
              <main className="min-h-screen w-full">
                <AppRoutes />
              </main>
            </ToastProvider>
          </AuthProvider>
        </NotificationsProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
}
