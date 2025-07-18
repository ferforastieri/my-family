import firestore from '@react-native-firebase/firestore';
import storage from '@react-native-firebase/storage';

// Configuração manual do Firestore
export const firestoreConfig = {
  // Configurações específicas do Firestore se necessário
  settings: {
    cacheSizeBytes: firestore.CACHE_SIZE_UNLIMITED,
  }
};

// Configuração manual do Storage
export const storageConfig = {
  // Configurações específicas do Storage se necessário
};

// Inicializar configurações
export const initializeFirebase = () => {
  // Configurar Firestore
  firestore().settings(firestoreConfig.settings);
  
  console.log('✅ Firebase Firestore e Storage configurados manualmente');
};

export default {
  firestore: firestore(),
  storage: storage(),
  initializeFirebase
}; 