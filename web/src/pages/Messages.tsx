import styled from 'styled-components';

const MessagesContainer = styled.div`
  min-height: 100vh;
  padding: 80px 2rem 2rem;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
`;

const Title = styled.h1`
  color: #ff69b4;
  font-size: 2.5rem;
  font-family: 'Dancing Script', cursive;
  text-align: center;
  margin-bottom: 2rem;
`;

const MessageGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
`;

const MessageCard = styled.div`
  background: rgba(255, 255, 255, 0.9);
  padding: 2rem;
  border-radius: 15px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease;
  
  &:hover {
    transform: translateY(-5px);
  }

  h3 {
    color: #ff1493;
    font-size: 1.5rem;
    margin-bottom: 1rem;
    font-family: 'Pacifico', cursive;
  }

  p {
    color: #666;
    line-height: 1.6;
    font-size: 1.1rem;
  }

  .date {
    color: #ff69b4;
    font-size: 0.9rem;
    margin-top: 1rem;
    text-align: right;
    font-style: italic;
  }
`;

const Messages = () => {
  const messages = [
    {
      id: 1,
      title: "Meu Amor",
      content: "Cada dia ao seu lado é uma nova aventura cheia de amor e felicidade...",
      date: "10 de Novembro, 2024"
    },
    {
      id: 2,
      title: "Para Sempre",
      content: "Você é o sonho que eu não sabia que tinha até te encontrar...",
      date: "11 de Fevereiro, 2024"
    },
    // Adicione mais mensagens conforme necessário
  ];

  return (
    <MessagesContainer>
      <Title>Mensagens do Coração</Title>
      <MessageGrid>
        {messages.map(message => (
          <MessageCard key={message.id}>
            <h3>{message.title}</h3>
            <p>{message.content}</p>
            <p className="date">{message.date}</p>
          </MessageCard>
        ))}
      </MessageGrid>
    </MessagesContainer>
  );
};

export default Messages; 