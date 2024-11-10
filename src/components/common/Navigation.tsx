import styled from 'styled-components';
import { Link } from 'react-router-dom';
import { useState } from 'react';

const Nav = styled.nav<{ isOpen: boolean }>`
  position: fixed;
  top: 0;
  left: 0;
  height: 100vh;
  width: ${props => props.isOpen ? '250px' : '60px'};
  background: linear-gradient(to bottom, #fff0f5, #fff8fa);
  padding: 1rem 0.5rem;
  z-index: 100;
  box-shadow: 2px 0 15px rgba(255, 105, 180, 0.15);
  transition: all 0.3s ease-in-out;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
`;

const ToggleButton = styled.button<{ isOpen: boolean }>`
  position: absolute;
  top: 1rem;
  right: ${props => props.isOpen ? '1rem' : '50%'};
  transform: ${props => props.isOpen ? 'none' : 'translateX(50%)'};
  background: transparent;
  border: none;
  cursor: pointer;
  color: #ff69b4;
  font-size: 1.3rem;
  transition: all 0.3s ease;
  padding: 0.5rem;
  border-radius: 50%;
  width: 35px;
  height: 35px;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &:hover {
    background: rgba(255, 105, 180, 0.1);
    transform: ${props => props.isOpen ? 'scale(1.1)' : 'translateX(50%) scale(1.1)'};
  }
`;

const NavList = styled.ul<{ isOpen: boolean }>`
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
  list-style: none;
  padding: 0;
  margin-top: 4rem;
  width: 100%;
  align-items: ${props => props.isOpen ? 'flex-start' : 'center'};
`;

const NavItem = styled.li<{ isOpen: boolean }>`
  position: relative;
  width: 100%;
  display: flex;
  justify-content: center;
  
  &::before {
    content: '♥';
    position: absolute;
    left: 0;
    top: 50%;
    transform: translateY(-50%);
    color: #ff69b4;
    font-size: 0.8rem;
    opacity: 0;
    transition: opacity 0.3s ease;
  }
  
  &:hover::before {
    opacity: ${({ isOpen }) => isOpen ? 1 : 0};
  }
`;

const NavLink = styled(Link)<{ isOpen: boolean }>`
  color: #ff69b4;
  font-size: 1.2rem;
  font-family: 'Dancing Script', cursive;
  text-decoration: none;
  padding: 0.8rem;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  white-space: nowrap;
  justify-content: ${props => props.isOpen ? 'flex-start' : 'center'};
  width: 100%;
  
  &:hover {
    color: #ff1493;
    transform: translateX(${props => props.isOpen ? '10px' : '0'});
    background: rgba(255, 105, 180, 0.1);
    border-radius: 8px;
  }
  
  &.active {
    color: #ff1493;
    font-weight: bold;
    background: rgba(255, 105, 180, 0.05);
    border-radius: 8px;
  }

  .icon {
    font-size: 1.4rem;
    margin-right: ${props => props.isOpen ? '1rem' : '0'};
    min-width: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 1;
  }

  .text {
    opacity: ${props => props.isOpen ? 1 : 0};
    transition: opacity 0.2s ease;
    font-size: 1.1rem;
    display: ${props => props.isOpen ? 'block' : 'none'};
  }
`;

const Navigation = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <Nav isOpen={isOpen}>
      <ToggleButton 
        isOpen={isOpen} 
        onClick={() => setIsOpen(!isOpen)}
        aria-label={isOpen ? 'Fechar menu' : 'Abrir menu'}
      >
        {isOpen ? '◀' : '▶'}
      </ToggleButton>
      <NavList isOpen={isOpen}>
        <NavItem isOpen={isOpen}>
          <NavLink to="/" isOpen={isOpen}>
            <span className="icon">🏠</span>
            <span className="text">Nosso Início</span>
          </NavLink>
        </NavItem>
        <NavItem isOpen={isOpen}>
          <NavLink to="/nossa-historia" isOpen={isOpen}>
            <span className="icon">📖</span>
            <span className="text">Nossa Jornada</span>
          </NavLink>
        </NavItem>
        <NavItem isOpen={isOpen}>
          <NavLink to="/momentos" isOpen={isOpen}>
            <span className="icon">✨</span>
            <span className="text">Momentos Mágicos</span>
          </NavLink>
        </NavItem>
        <NavItem isOpen={isOpen}>
          <NavLink to="/galeria" isOpen={isOpen}>
            <span className="icon">📸</span>
            <span className="text">Memórias em Fotos</span>
          </NavLink>
        </NavItem>
        <NavItem isOpen={isOpen}>
          <NavLink to="/mensagens" isOpen={isOpen}>
            <span className="icon">💌</span>
            <span className="text">Palavras do Coração</span>
          </NavLink>
        </NavItem>
      </NavList>
    </Nav>
  );
};

export default Navigation;