import { BrowserRouter } from 'react-router-dom';
import { GlobalStyle } from './assets/styles/global';
import { AppRoutes } from './routes';
import Navigation from './components/common/Navigation';
import './styles/flower.css';
import { useState } from 'react';
import styled from 'styled-components';
import { AuthProvider } from './contexts/AuthContext';

const MainContent = styled.div<{ isOpen: boolean }>`
  margin-left: ${props => props.isOpen ? '250px' : '60px'};
  width: calc(100% - ${props => props.isOpen ? '250px' : '60px'});
  transition: margin-left 0.2s ease, width 0.2s ease;
  min-height: 100vh;
`;

function App() {
  const [isNavOpen, setIsNavOpen] = useState(false);

  return (
    <BrowserRouter>
      <AuthProvider>
        <GlobalStyle />
        <Navigation onToggle={setIsNavOpen} />
        <MainContent isOpen={isNavOpen}>
          <AppRoutes />
        </MainContent>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
