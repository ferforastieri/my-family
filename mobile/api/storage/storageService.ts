import storage from '@react-native-firebase/storage';
import firestore from '@react-native-firebase/firestore';
import { Platform } from 'react-native';

export interface GalleryItem {
  id: string;
  name: string;
  url: string;
  description: string;
  type: 'image' | 'video' | 'document';
  size: number;
  createdAt: Date;
  updatedAt: Date;
  uploadedBy: string;
}

class StorageService {
  // Upload de arquivo para Firebase Storage
  async uploadFile(
    fileUri: string,
    fileName: string,
    description: string,
    userId: string
  ): Promise<GalleryItem> {
    try {
      // Criar referência no storage
      const storageRef = storage().ref(`users/${userId}/gallery/${fileName}`);
      
      // Upload do arquivo
      const uploadTask = storageRef.putFile(fileUri);
      
      // Aguardar upload
      await uploadTask;
      
      // Obter URL de download
      const downloadUrl = await storageRef.getDownloadURL();
      
      const now = new Date();
      
      // Criar documento no Firestore
      const fileData: Omit<GalleryItem, 'id'> = {
        name: fileName,
        url: downloadUrl,
        description,
        type: this.getFileType(fileName),
        size: 0,
        createdAt: now,
        updatedAt: now,
        uploadedBy: userId,
      };
      
      const docRef = await firestore()
        .collection('users')
        .doc(userId)
        .collection('gallery')
        .add(fileData);
      
      // Atualizar com o ID
      const uploadedFile: GalleryItem = {
        id: docRef.id,
        ...fileData,
      };
      
      console.log('Arquivo enviado com sucesso:', uploadedFile);
      return uploadedFile;
    } catch (error) {
      console.error('Erro ao enviar arquivo:', error);
      throw error;
    }
  }

  // Obter arquivos do usuário
  async getUserFiles(userId: string): Promise<GalleryItem[]> {
    try {
      const snapshot = await firestore()
        .collection('users')
        .doc(userId)
        .collection('gallery')
        .orderBy('createdAt', 'desc')
        .get();
      
      const files: GalleryItem[] = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        files.push({
          id: doc.id,
          name: data.name,
          url: data.url,
          description: data.description || '',
          type: data.type,
          size: data.size || 0,
          createdAt: data.createdAt.toDate(),
          updatedAt: data.updatedAt.toDate(),
          uploadedBy: data.uploadedBy,
        });
      });
      
      return files;
    } catch (error) {
      console.error('Erro ao obter arquivos:', error);
      throw error;
    }
  }

  // Atualizar descrição do arquivo
  async updateFileDescription(
    userId: string,
    fileId: string,
    description: string
  ): Promise<void> {
    try {
      await firestore()
        .collection('users')
        .doc(userId)
        .collection('gallery')
        .doc(fileId)
        .update({
          description,
          updatedAt: new Date(),
        });
      
      console.log('Descrição atualizada com sucesso');
    } catch (error) {
      console.error('Erro ao atualizar descrição:', error);
      throw error;
    }
  }

  // Deletar arquivo
  async deleteFile(userId: string, fileId: string, fileName: string): Promise<void> {
    try {
      // Deletar do Firestore
      await firestore()
        .collection('users')
        .doc(userId)
        .collection('gallery')
        .doc(fileId)
        .delete();
      
      // Deletar do Storage
      const storageRef = storage().ref(`users/${userId}/gallery/${fileName}`);
      await storageRef.delete();
      
      console.log('Arquivo deletado com sucesso');
    } catch (error) {
      console.error('Erro ao deletar arquivo:', error);
      throw error;
    }
  }

  // Obter URL de preview
  async getPreviewUrl(filePath: string): Promise<string> {
    try {
      const storageRef = storage().ref(filePath);
      return await storageRef.getDownloadURL();
    } catch (error) {
      console.error('Erro ao obter URL de preview:', error);
      throw error;
    }
  }

  // Verificar se arquivo é imagem
  isImage(fileName: string): boolean {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    const extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return imageExtensions.includes(extension);
  }

  // Verificar se arquivo é vídeo
  isVideo(fileName: string): boolean {
    const videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm'];
    const extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return videoExtensions.includes(extension);
  }

  // Obter tipo de arquivo
  private getFileType(fileName: string): 'image' | 'video' | 'document' {
    if (this.isImage(fileName)) return 'image';
    if (this.isVideo(fileName)) return 'video';
    return 'document';
  }

  // Obter tamanho do arquivo (em bytes)
  async getFileSize(fileUri: string): Promise<number> {
    try {
      // Para React Native, você pode usar react-native-fs para obter o tamanho
      // Por enquanto, retornamos 0
      return 0;
    } catch (error) {
      console.error('Erro ao obter tamanho do arquivo:', error);
      return 0;
    }
  }
}

export default new StorageService(); 