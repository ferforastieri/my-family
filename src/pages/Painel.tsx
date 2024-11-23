import styled from 'styled-components';

const PainelContainer = styled.div`
  padding: 2rem;
  min-height: 100vh;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
`;

const Title = styled.h1`
  color: #ff69b4;
  font-family: 'Pacifico', cursive;
  font-size: 2.5rem;
  text-align: center;
  margin-bottom: 2rem;
`;

const AdminSection = styled.section`
  background: white;
  border-radius: 15px;
  padding: 2rem;
  margin-bottom: 2rem;
  box-shadow: 0 4px 15px rgba(255, 105, 180, 0.1);
`;

const SectionTitle = styled.h2`
  color: #ff69b4;
  font-family: 'Dancing Script', cursive;
  font-size: 1.8rem;
  margin-bottom: 1rem;
`;

const AdminGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-top: 1rem;
`;

const AdminCard = styled.div`
  background: #fff8fa;
  padding: 1.5rem;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(255, 105, 180, 0.1);
  transition: transform 0.2s ease;
  cursor: pointer;

  &:hover {
    transform: translateY(-5px);
  }

  h3 {
    color: #ff69b4;
    font-family: 'Dancing Script', cursive;
    font-size: 1.5rem;
    margin-bottom: 0.5rem;
  }

  p {
    color: #666;
    font-size: 0.9rem;
  }
`;

const Painel = () => {
  return (
    <PainelContainer>
      <Title>Painel Administrativo</Title>

      <AdminSection>
        <SectionTitle>Gerenciar Conteúdo</SectionTitle>
        <AdminGrid>
          <AdminCard>
            <h3>Galeria de Fotos</h3>
            <p>Adicionar, remover ou editar fotos da galeria privada.</p>
          </AdminCard>
          <AdminCard>
            <h3>Mensagens</h3>
            <p>Gerenciar mensagens e declarações de amor.</p>
          </AdminCard>
          <AdminCard>
            <h3>Quiz do Amor</h3>
            <p>Editar perguntas e respostas do quiz.</p>
          </AdminCard>
          <AdminCard>
            <h3>Carta de Amor</h3>
            <p>Atualizar o conteúdo da carta de amor.</p>
          </AdminCard>
        </AdminGrid>
      </AdminSection>

      <AdminSection>
        <SectionTitle>Configurações</SectionTitle>
        <AdminGrid>
          <AdminCard>
            <h3>Alterar Senha</h3>
            <p>Modificar a senha de acesso ao painel.</p>
          </AdminCard>
          <AdminCard>
            <h3>Backup</h3>
            <p>Fazer backup dos dados e conteúdos.</p>
          </AdminCard>
        </AdminGrid>
      </AdminSection>
    </PainelContainer>
  );
};

export default Painel; 