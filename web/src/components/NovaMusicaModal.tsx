import styled from 'styled-components';
import { useState } from 'react';

const ModalOverlay = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  padding: 1rem;
  backdrop-filter: blur(5px);
`;

const ModalContent = styled.div`
  background: linear-gradient(to bottom, #fff8fa, #fff);
  padding: 2.5rem;
  border-radius: 20px;
  width: 90%;
  max-width: 600px;
  box-shadow: 0 10px 30px rgba(255, 105, 180, 0.2);
  animation: slideIn 0.3s ease-out;

  @keyframes slideIn {
    from {
      transform: translateY(-20px);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }
`;

const ModalTitle = styled.h2`
  color: #ff69b4;
  font-family: 'Pacifico', cursive;
  font-size: 2rem;
  text-align: center;
  margin-bottom: 1.5rem;
`;

const Form = styled.form`
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
`;

const Input = styled.input`
  padding: 1rem;
  border: 2px solid #ffe6f2;
  border-radius: 12px;
  font-family: 'Dancing Script', cursive;
  font-size: 1.1rem;
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.9);
  
  &:focus {
    outline: none;
    border-color: #ff69b4;
    box-shadow: 0 0 10px rgba(255, 105, 180, 0.2);
  }

  &::placeholder {
    color: #ccc;
  }
`;

const TextArea = styled.textarea`
  padding: 1rem;
  border: 2px solid #ffe6f2;
  border-radius: 12px;
  font-family: 'Dancing Script', cursive;
  font-size: 1.1rem;
  min-height: 150px;
  resize: vertical;
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.9);
  
  &:focus {
    outline: none;
    border-color: #ff69b4;
    box-shadow: 0 0 10px rgba(255, 105, 180, 0.2);
  }

  &::placeholder {
    color: #ccc;
  }
`;

const Select = styled.select`
  padding: 1rem;
  border: 2px solid #ffe6f2;
  border-radius: 12px;
  font-family: 'Dancing Script', cursive;
  font-size: 1.1rem;
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.9);
  
  &:focus {
    outline: none;
    border-color: #ff69b4;
    box-shadow: 0 0 10px rgba(255, 105, 180, 0.2);
  }
`;

const ButtonContainer = styled.div`
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1rem;
`;

const Button = styled.button`
  padding: 0.8rem 2rem;
  border-radius: 25px;
  font-family: 'Dancing Script', cursive;
  font-size: 1.1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
  
  &:hover {
    transform: translateY(-2px);
  }
`;

const SaveButton = styled(Button)`
  background: #ff69b4;
  color: white;
  box-shadow: 0 2px 10px rgba(255, 105, 180, 0.3);
  
  &:hover {
    background: #ff1493;
    box-shadow: 0 4px 15px rgba(255, 105, 180, 0.4);
  }
`;

const CancelButton = styled(Button)`
  background: transparent;
  color: #ff69b4;
  border: 2px solid #ff69b4;
  
  &:hover {
    background: #fff0f5;
  }
`;

const momentos = [
  'Primeiro Encontro',
  'Primeiro Beijo',
  'Pedido de Namoro',
  'Noivado',
  'Casamento',
  'Lua de Mel',
  'Momentos Especiais',
  'Outros'
];

interface NovaMusicaModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (musica: {
    titulo: string;
    artista: string;
    link_spotify: string;
    descricao: string;
    momento: string;
  }) => Promise<void>;
}

export const NovaMusicaModal = ({ isOpen, onClose, onSave }: NovaMusicaModalProps) => {
  const [titulo, setTitulo] = useState('');
  const [artista, setArtista] = useState('');
  const [linkSpotify, setLinkSpotify] = useState('');
  const [descricao, setDescricao] = useState('');
  const [momento, setMomento] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSave({
      titulo,
      artista,
      link_spotify: linkSpotify,
      descricao,
      momento
    });
    
    // Limpar formulário
    setTitulo('');
    setArtista('');
    setLinkSpotify('');
    setDescricao('');
    setMomento('');
    
    onClose();
  };

  return (
    <ModalOverlay onClick={onClose}>
      <ModalContent onClick={e => e.stopPropagation()}>
        <ModalTitle>Adicionar Nova Música</ModalTitle>
        <Form onSubmit={handleSubmit}>
          <Input
            type="text"
            placeholder="Nome da música"
            value={titulo}
            onChange={e => setTitulo(e.target.value)}
            required
          />
          <Input
            type="text"
            placeholder="Artista"
            value={artista}
            onChange={e => setArtista(e.target.value)}
            required
          />
          <Input
            type="url"
            placeholder="Link do Spotify ou YouTube"
            value={linkSpotify}
            onChange={e => setLinkSpotify(e.target.value)}
          />
          <Select
            value={momento}
            onChange={e => setMomento(e.target.value)}
            required
          >
            <option value="">Selecione o momento...</option>
            {momentos.map(m => (
              <option key={m} value={m}>{m}</option>
            ))}
          </Select>
          <TextArea
            placeholder="Por que essa música é especial?"
            value={descricao}
            onChange={e => setDescricao(e.target.value)}
            required
          />
          <ButtonContainer>
            <CancelButton type="button" onClick={onClose}>
              Cancelar
            </CancelButton>
            <SaveButton type="submit">
              Adicionar Música
            </SaveButton>
          </ButtonContainer>
        </Form>
      </ModalContent>
    </ModalOverlay>
  );
}; 