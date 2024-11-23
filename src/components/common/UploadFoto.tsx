import { useState } from 'react';
import styled from 'styled-components';
import { uploadToCloudinary } from '../../services/cloudinary';

const UploadContainer = styled.div`
  margin: 1rem 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
`;

const UploadButton = styled.button`
  background: #ff69b4;
  color: white;
  padding: 0.8rem 1.5rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-family: 'Dancing Script', cursive;
  font-size: 1.1rem;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(255, 105, 180, 0.2);

  &:hover {
    background: #ff1493;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(255, 105, 180, 0.3);
  }

  &:disabled {
    background: #ffb6c1;
    cursor: not-allowed;
    transform: none;
  }
`;

const UploadInput = styled.input`
  display: none;
`;

const ProgressBar = styled.div<{ progress: number }>`
  width: 200px;
  height: 6px;
  background: #ffe6f2;
  border-radius: 3px;
  overflow: hidden;
  position: relative;

  &::after {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    height: 100%;
    width: ${props => props.progress}%;
    background: #ff69b4;
    transition: width 0.3s ease;
  }
`;

const StatusMessage = styled.p`
  color: #ff69b4;
  font-family: 'Dancing Script', cursive;
  font-size: 1rem;
  margin: 0;
`;

interface UploadFotoProps {
  onUploadComplete: (url: string) => void;
}

const UploadFoto = ({ onUploadComplete }: UploadFotoProps) => {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/') && !file.type.startsWith('video/')) {
      alert('Por favor, selecione apenas arquivos de imagem ou vídeo.');
      return;
    }

    const isVideo = file.type.startsWith('video/');
    const maxSize = isVideo ? 50 * 1024 * 1024 : 5 * 1024 * 1024;
    
    if (file.size > maxSize) {
      alert(`O arquivo deve ter no máximo ${isVideo ? '50MB' : '5MB'}.`);
      return;
    }

    setUploading(true);
    setProgress(20);

    try {
      const result = await uploadToCloudinary(file);
      setProgress(100);
      onUploadComplete(result.secure_url);
    } catch (error) {
      console.error('Erro no upload:', error);
      alert('Erro ao fazer upload do arquivo. Por favor, tente novamente.');
    } finally {
      setUploading(false);
      setTimeout(() => setProgress(0), 1000);
    }
  };

  return (
    <UploadContainer>
      <UploadInput
        type="file"
        id="foto-upload"
        accept="image/*,video/*"
        onChange={handleUpload}
        disabled={uploading}
      />
      <UploadButton
        as="label"
        htmlFor="foto-upload"
        disabled={uploading}
      >
        {uploading ? 'Enviando...' : 'Adicionar Foto ou Vídeo'}
      </UploadButton>
      
      {uploading && (
        <>
          <ProgressBar progress={progress} />
          <StatusMessage>
            {progress < 100 ? 'Enviando arquivo...' : 'Upload concluído!'}
          </StatusMessage>
        </>
      )}
    </UploadContainer>
  );
};

export default UploadFoto; 