import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Animated } from 'react-native';

export default function MessagesScreen() {
  const [expandedMessage, setExpandedMessage] = useState<string | null>(null);

  const messages = [
    {
      id: '1',
      title: 'Meu Amor por Você',
      content: 'Cada dia ao seu lado é uma nova aventura, um novo motivo para sorrir...',
      color: '#ff69b4'
    },
    {
      id: '2',
      title: 'Nossa Conexão',
      content: 'O que temos é especial, uma conexão única que transcende o comum...',
      color: '#ff1493'
    },
    {
      id: '3',
      title: 'Gratidão',
      content: 'Sou grato(a) por ter você em minha vida, por compartilhar momentos...',
      color: '#db7093'
    },
    {
      id: '4',
      title: 'Nosso Futuro',
      content: 'Sonho com nosso futuro juntos, com todas as aventuras que viveremos...',
      color: '#c71585'
    },
  ];

  const toggleMessage = (messageId: string) => {
    setExpandedMessage(expandedMessage === messageId ? null : messageId);
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.pageTitle}>Mensagens do Coração ❤️</Text>
      
      <View style={styles.messagesContainer}>
        {messages.map((message) => (
          <TouchableOpacity
            key={message.id}
            style={[styles.messageCard, { backgroundColor: message.color }]}
            onPress={() => toggleMessage(message.id)}
          >
            <Text style={styles.messageTitle}>{message.title}</Text>
            {expandedMessage === message.id && (
              <Text style={styles.messageContent}>{message.content}</Text>
            )}
          </TouchableOpacity>
        ))}
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Toque nos cartões para ler as mensagens completas 💝
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
    padding: 20,
  },
  pageTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#ff69b4',
    textAlign: 'center',
    marginBottom: 30,
  },
  messagesContainer: {
    gap: 15,
  },
  messageCard: {
    borderRadius: 15,
    padding: 20,
    elevation: 3,
  },
  messageTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 10,
  },
  messageContent: {
    fontSize: 16,
    color: 'white',
    lineHeight: 24,
  },
  footer: {
    marginTop: 30,
    alignItems: 'center',
  },
  footerText: {
    color: '#666',
    fontSize: 14,
    fontStyle: 'italic',
  },
}); 