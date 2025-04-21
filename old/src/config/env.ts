console.log('Variáveis de ambiente:', {
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL,
  cloudinaryName: import.meta.env.VITE_CLOUDINARY_CLOUD_NAME
});

interface EnvConfig {
  supabase: {
    url: string;
    anonKey: string;
  };
  cloudinary: {
    cloudName: string;
    uploadPreset: string;
  };
}

if (!import.meta.env.VITE_SUPABASE_URL || 
    !import.meta.env.VITE_SUPABASE_ANON_KEY || 
    !import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || 
    !import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET) {
  console.error('Variáveis faltando:', {
    supabaseUrl: !!import.meta.env.VITE_SUPABASE_URL,
    supabaseKey: !!import.meta.env.VITE_SUPABASE_ANON_KEY,
    cloudinaryName: !!import.meta.env.VITE_CLOUDINARY_CLOUD_NAME,
    uploadPreset: !!import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET
  });
  throw new Error('Variáveis de ambiente necessárias não encontradas');
}

export const config: EnvConfig = {
  supabase: {
    url: import.meta.env.VITE_SUPABASE_URL,
    anonKey: import.meta.env.VITE_SUPABASE_ANON_KEY
  },
  cloudinary: {
    cloudName: import.meta.env.VITE_CLOUDINARY_CLOUD_NAME,
    uploadPreset: import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET
  }
}; 