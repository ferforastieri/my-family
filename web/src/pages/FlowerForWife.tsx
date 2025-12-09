import styled from 'styled-components';
import { useEffect } from 'react';

const PageContainer = styled.div`
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  padding: 2rem;
  position: relative;
  overflow: hidden;
`;

const Title = styled.h1`
  color: #d4488e;
  font-size: 3.5rem;
  font-family: 'Pacifico', cursive;
  text-align: center;
  margin-bottom: 2rem;
  z-index: 2;
  text-shadow: 2px 2px 4px rgba(212, 72, 142, 0.3);
  background: linear-gradient(45deg, #ff69b4, #d4488e);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: titleGlow 2s ease-in-out infinite alternate;

  @keyframes titleGlow {
    from {
      filter: drop-shadow(0 0 2px rgba(255, 105, 180, 0.3));
    }
    to {
      filter: drop-shadow(0 0 5px rgba(255, 105, 180, 0.6));
    }
  }
`;

const FlowerContainer = styled.div`
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 80vh;
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: flex-end;
`;

const FlowerForWife = () => {
  useEffect(() => {
    document.body.classList.remove('not-loaded');
    document.body.removeAttribute('style');
  }, []);

  return (
    <PageContainer>
      <Title>Uma Flor para Minha Esposa</Title>
      <FlowerContainer>
        <div className="night"></div>
        <div className="flowers">
          <div className="flower flower--1">
            <div className="flower__leafs flower__leafs--1">
              <div className="flower__leaf flower__leaf--1"></div>
              <div className="flower__leaf flower__leaf--2"></div>
              <div className="flower__leaf flower__leaf--3"></div>
              <div className="flower__leaf flower__leaf--4"></div>
              <div className="flower__white-circle"></div>
            </div>
            <div className="flower__line">
              <div className="flower__line__leaf flower__line__leaf--1"></div>
              <div className="flower__line__leaf flower__line__leaf--2"></div>
              <div className="flower__line__leaf flower__line__leaf--3"></div>
              <div className="flower__line__leaf flower__line__leaf--4"></div>
            </div>
          </div>
          
          <div className="grow-ans" style={{ '--d': '1.2s' } as React.CSSProperties}>
            <div className="flower__g-long">
              <div className="flower__g-long__top"></div>
              <div className="flower__g-long__bottom"></div>
            </div>
          </div>
          
          <div className="growing-grass">
            <div className="flower__grass flower__grass--1">
              <div className="flower__grass--top"></div>
              <div className="flower__grass--bottom"></div>
              <div className="flower__grass__leaf flower__grass__leaf--1"></div>
              <div className="flower__grass__leaf flower__grass__leaf--2"></div>
              <div className="flower__grass__leaf flower__grass__leaf--3"></div>
              <div className="flower__grass__leaf flower__grass__leaf--4"></div>
              <div className="flower__grass__leaf flower__grass__leaf--5"></div>
              <div className="flower__grass__leaf flower__grass__leaf--6"></div>
              <div className="flower__grass__leaf flower__grass__leaf--7"></div>
              <div className="flower__grass__leaf flower__grass__leaf--8"></div>
              <div className="flower__grass__overlay"></div>
            </div>
          </div>
        </div>
      </FlowerContainer>
    </PageContainer>
  );
};

export default FlowerForWife; 