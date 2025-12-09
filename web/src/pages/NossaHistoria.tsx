import styled, { keyframes } from 'styled-components';

const floatAnimation = keyframes`
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
`;

const glowAnimation = keyframes`
  0%, 100% { text-shadow: 2px 2px 4px rgba(255, 105, 180, 0.3); }
  50% { text-shadow: 2px 2px 12px rgba(255, 105, 180, 0.6); }
`;

const Container = styled.div`
  width: 100%;
  min-height: 100vh;
  padding: 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
`;

const Title = styled.h1`
  color: #ff69b4;
  font-size: 3.5rem;
  font-family: 'Pacifico', cursive;
  text-align: center;
  margin-bottom: 2rem;
  animation: ${floatAnimation} 3s ease-in-out infinite,
             ${glowAnimation} 2s ease-in-out infinite;

  @media (max-width: 768px) {
    font-size: 2.5rem;
  }
`;

const Content = styled.div`
  display: flex;
  flex-direction: column;
  gap: 2rem;
  max-width: 1000px;
  margin: 0 auto;
`;

const Section = styled.section`
  background: rgba(255, 255, 255, 0.9);
  padding: 2rem;
  border-radius: 15px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(5px);
  transition: transform 0.3s ease;

  &:hover {
    transform: translateY(-5px);
    background: rgba(255, 255, 255, 0.95);
  }

  h2 {
    color: #ff69b4;
    font-size: 1.8rem;
    margin-bottom: 1rem;
    font-family: 'Dancing Script', cursive;
  }

  p {
    color: #666;
    line-height: 1.6;
    font-size: 1.1rem;
  }
`;

const NossaHistoria = () => {
  return (
    <Container>
      <Title>Nossa História</Title>
      <Content>
        <Section>
          <h2>Como Nos Conhecemos</h2>
          <p>
            Nossa história começou de uma forma moderna e especial, através de um 
            aplicativo de relacionamento da nossa igreja. O que começou como uma 
            simples conversa logo se transformou em algo muito especial.
          </p>
        </Section>

        <Section>
          <h2>Nosso Relacionamento</h2>
          <p>
            Oficialmente começamos nosso namoro em 15 de outubro de 2024. 
            Desde então, temos compartilhado momentos incríveis juntos, 
            construindo uma relação baseada em amor, respeito e valores em comum.
          </p>
        </Section>

        <Section>
          <h2>Nossa Conexão</h2>
          <p>
            Nossa fé e valores compartilhados têm sido a base do nosso relacionamento. 
            Unidos pela igreja e por nossos princípios, construímos uma conexão 
            verdadeira e especial.
          </p>
        </Section>
      </Content>
    </Container>
  );
};

export default NossaHistoria;