import { config } from '../config/env';

interface CloudinaryResponse {
  secure_url: string;
  public_id: string;
  resource_type: string;
}

export const uploadToCloudinary = async (file: File): Promise<CloudinaryResponse> => {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', config.cloudinary.uploadPreset);
  
  const resourceType = file.type.startsWith('video/') ? 'video' : 'image';
  
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${config.cloudinary.cloudName}/${resourceType}/upload`,
    {
      method: 'POST',
      body: formData,
    }
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Erro no upload para o Cloudinary');
  }

  return response.json();
}; 