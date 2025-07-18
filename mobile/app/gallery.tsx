import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Alert,
  Modal,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { FontAwesome } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import Button from '../components/Button';
import Toast from '../components/Toast';
import { useAuth } from '../hooks/useAuth';
import storageService, { GalleryItem } from '../api/storage/storageService';

export default function Gallery() {
  const { user, isAuthenticated } = useAuth();
  const [files, setFiles] = useState<GalleryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [editModal, setEditModal] = useState(false);
  const [selectedFile, setSelectedFile] = useState<GalleryItem | null>(null);
  const [editDescription, setEditDescription] = useState('');

  // Carregar arquivos
  const loadFiles = async () => {
    if (!user?.uid) return;
    
    setLoading(true);
    try {
      const userFiles = await storageService.getUserFiles(user.uid);
      setFiles(userFiles);
    } catch (error) {
      setToast({ type: 'error', message: 'Erro ao carregar arquivos' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isAuthenticated && user?.uid) {
      loadFiles();
    }
  }, [isAuthenticated, user?.uid]);

  // Selecionar imagem
  const pickImage = async () => {
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.All,
        allowsEditing: true,
        aspect: [4, 3],
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        await uploadFile(result.assets[0].uri, result.assets[0].fileName || 'image.jpg');
      }
    } catch (error) {
      setToast({ type: 'error', message: 'Erro ao selecionar imagem' });
    }
  };

  // Upload de arquivo
  const uploadFile = async (fileUri: string, fileName: string) => {
    if (!user?.uid) return;

    setUploading(true);
    try {
      const description = `Foto enviada em ${new Date().toLocaleDateString()}`;
      const uploadedFile = await storageService.uploadFile(fileUri, fileName, description, user.uid);
      
      setFiles(prev => [uploadedFile, ...prev]);
      setToast({ type: 'success', message: 'Arquivo enviado com sucesso!' });
    } catch (error) {
      setToast({ type: 'error', message: 'Erro ao enviar arquivo' });
    } finally {
      setUploading(false);
    }
  };

  // Editar arquivo
  const editFile = (file: GalleryItem) => {
    setSelectedFile(file);
    setEditDescription(file.description);
    setEditModal(true);
  };

  // Salvar edição
  const saveEdit = async () => {
    if (!selectedFile || !user?.uid) return;

    try {
      await storageService.updateFileDescription(user.uid, selectedFile.id, editDescription);
      
      setFiles(prev => prev.map(file => 
        file.id === selectedFile.id 
          ? { ...file, description: editDescription, updatedAt: new Date() }
          : file
      ));
      
      setEditModal(false);
      setSelectedFile(null);
      setToast({ type: 'success', message: 'Descrição atualizada!' });
    } catch (error) {
      setToast({ type: 'error', message: 'Erro ao atualizar descrição' });
    }
  };

  // Deletar arquivo
  const deleteFile = (file: GalleryItem) => {
    if (!user?.uid) return;

    Alert.alert(
      'Deletar arquivo',
      'Tem certeza que deseja deletar este arquivo?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Deletar',
          style: 'destructive',
          onPress: async () => {
            try {
              await storageService.deleteFile(user.uid, file.id, file.name);
              setFiles(prev => prev.filter(f => f.id !== file.id));
              setToast({ type: 'success', message: 'Arquivo deletado!' });
            } catch (error) {
              setToast({ type: 'error', message: 'Erro ao deletar arquivo' });
            }
          },
        },
      ]
    );
  };

  // Formatar data
  const formatDate = (date: Date) => {
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (!isAuthenticated) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>📸 Nossa Galeria</Text>
        <Text style={styles.subtitle}>
          Faça login para acessar nossa galeria de fotos e vídeos especiais! 💕
        </Text>
        <Button 
          title="Fazer Login" 
          onPress={() => {}} 
          variant="primary"
        />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>📸 Nossa Galeria</Text>
      
      {/* Botão de Upload */}
      <View style={styles.uploadSection}>
        <Button
          title={uploading ? "Enviando..." : "📷 Adicionar Foto/Vídeo"}
          onPress={pickImage}
          variant="primary"
          loading={uploading}
          disabled={uploading}
        />
      </View>

      {/* Lista de Arquivos */}
      <ScrollView style={styles.filesContainer}>
        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#ff69b4" />
            <Text style={styles.loadingText}>Carregando arquivos...</Text>
          </View>
        ) : files.length === 0 ? (
          <View style={styles.emptyContainer}>
            <FontAwesome name="image" size={64} color="#ccc" />
            <Text style={styles.emptyText}>Nenhuma foto ainda</Text>
            <Text style={styles.emptySubtext}>
              Adicione suas primeiras fotos e vídeos especiais! 💕
            </Text>
          </View>
        ) : (
          files.map((file) => (
            <View key={file.id} style={styles.fileCard}>
              {/* Preview da imagem */}
              <Image source={{ uri: file.url }} style={styles.filePreview} />
              
              {/* Informações do arquivo */}
              <View style={styles.fileInfo}>
                <Text style={styles.fileName}>{file.name}</Text>
                <Text style={styles.fileDescription}>{file.description}</Text>
                <Text style={styles.fileDate}>
                  Criado em {formatDate(file.createdAt)}
                </Text>
                {file.updatedAt.getTime() !== file.createdAt.getTime() && (
                  <Text style={styles.fileDate}>
                    Atualizado em {formatDate(file.updatedAt)}
                  </Text>
                )}
              </View>

              {/* Botões de ação */}
              <View style={styles.fileActions}>
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={() => editFile(file)}
                >
                  <FontAwesome name="edit" size={20} color="#ff69b4" />
                </TouchableOpacity>
                
                <TouchableOpacity
                  style={[styles.actionButton, styles.deleteButton]}
                  onPress={() => deleteFile(file)}
                >
                  <FontAwesome name="trash" size={20} color="#ff4444" />
                </TouchableOpacity>
              </View>
            </View>
          ))
        )}
      </ScrollView>

      {/* Modal de Edição */}
      <Modal
        visible={editModal}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setEditModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Editar Descrição</Text>
            
            <TextInput
              style={styles.descriptionInput}
              value={editDescription}
              onChangeText={setEditDescription}
              placeholder="Digite uma descrição para a foto..."
              multiline
              numberOfLines={3}
            />
            
            <View style={styles.modalActions}>
              <Button
                title="Cancelar"
                onPress={() => setEditModal(false)}
                variant="outline"
              />
              <Button
                title="Salvar"
                onPress={saveEdit}
                variant="primary"
              />
            </View>
          </View>
        </View>
      </Modal>

      {toast && (
        <Toast
          type={toast.type}
          message={toast.message}
          visible={true}
          onClose={() => setToast(null)}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
    color: '#ff69b4',
  },
  subtitle: {
    fontSize: 16,
    textAlign: 'center',
    color: '#666',
    marginBottom: 30,
  },
  uploadSection: {
    marginBottom: 20,
  },
  filesContainer: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#666',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 50,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#666',
    marginTop: 10,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    marginTop: 5,
  },
  fileCard: {
    backgroundColor: 'white',
    borderRadius: 10,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    overflow: 'hidden',
  },
  filePreview: {
    width: '100%',
    height: 200,
    resizeMode: 'cover',
  },
  fileInfo: {
    padding: 15,
  },
  fileName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 5,
  },
  fileDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 5,
  },
  fileDate: {
    fontSize: 12,
    color: '#999',
  },
  fileActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: 15,
    paddingTop: 0,
  },
  actionButton: {
    padding: 10,
    marginLeft: 10,
  },
  deleteButton: {
    // Estilo específico para botão de deletar se necessário
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 20,
    width: '90%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
  },
  descriptionInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 5,
    padding: 10,
    fontSize: 14,
    marginBottom: 20,
    minHeight: 80,
    textAlignVertical: 'top',
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
}); 