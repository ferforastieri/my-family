import styled from 'styled-components';

const LetterContainer = styled.div`
  min-height: 100vh;
  padding: 80px 2rem 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  display: flex;
  justify-content: center;
  align-items: center;
`;

const Letter = styled.div`
  background: rgba(255, 255, 255, 0.95);
  padding: 3rem;
  border-radius: 20px;
  box-shadow: 0 4px 20px rgba(255, 105, 180, 0.2);
  max-width: 800px;
  width: 100%;
  margin: 2rem;
  position: relative;
  
  &::before {
    content: '❤️';
    position: absolute;
    top: -20px;
    left: 50%;
    transform: translateX(-50%);
    font-size: 2.5rem;
  }
`;

const Content = styled.div`
  font-family: 'Dancing Script', cursive;
  color: #444;
  line-height: 2;
  font-size: 1.3rem;
  text-align: justify;
  
  p {
    margin-bottom: 1.5rem;
    text-indent: 2rem;
  }
  
  .greeting {
    font-size: 1.5rem;
    color: #ff69b4;
    margin-bottom: 2rem;
  }
  
  .signature {
    text-align: right;
    margin-top: 3rem;
    color: #ff69b4;
    font-size: 1.4rem;
  }
`;

const LoveLetter = () => {
  return (
    <LetterContainer>
      <Letter>
        <Content>
          <p className="greeting">Meu amor,</p>
          
          <p>
            Em cada amanhecer, meu primeiro pensamento é você. Em cada anoitecer, 
            meu último sorriso é por você. Entre esses momentos, cada batida do 
            meu coração ecoa seu nome, cada suspiro carrega a doçura do seu amor.
          </p>
          
          <p>
            Você é minha inspiração, minha força e minha paz. Com você, aprendi 
            que o amor não é apenas um sentimento, mas uma forma de viver. Cada 
            momento ao seu lado é uma nova descoberta, cada sorriso seu é um 
            presente que guardo no coração.
          </p>
          
          <p>
            Nosso amor é como um jardim em constante florescimento, onde cada 
            flor representa um momento especial que vivemos juntos. E assim como 
            essas flores, nosso amor cresce mais forte e mais bonito a cada dia.
          </p>
          
          <p>
            Obrigado por fazer parte da minha vida, por compartilhar seus sonhos 
            comigo e por me permitir fazer parte da sua história. Você é o amor 
            da minha vida, minha melhor amiga, minha companheira de aventuras.
          </p>
          
          <p>
            Te amo mais a cada dia, e prometo continuar cultivando nosso amor 
            com todo o carinho e dedicação que você merece.
          </p>
          
          <p className="signature">
            Com todo meu amor,<br/>
            Familia
          </p>
        </Content>
      </Letter>
    </LetterContainer>
  );
};

export default LoveLetter; 