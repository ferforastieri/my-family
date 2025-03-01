import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';

export default function HistoryScreen() {
  const timeline = [
    {
      date: '23 de Novembro de 2022',
      title: 'Nosso Primeiro Encontro',
      description: 'O dia em que nossos caminhos se cruzaram pela primeira vez...'
    },
    {
      date: '25 de Dezembro de 2022',
      title: 'Primeiro Natal Juntos',
      description: 'Celebramos nosso primeiro Natal como casal...'
    },
    // Adicione mais eventos importantes aqui
  ];

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.pageTitle}>Nossa História ❤️</Text>
      
      <View style={styles.timeline}>
        {timeline.map((event, index) => (
          <View key={index} style={styles.timelineItem}>
            <View style={styles.timelineLine} />
            <View style={styles.timelineDot} />
            
            <View style={styles.eventContent}>
              <Text style={styles.eventDate}>{event.date}</Text>
              <Text style={styles.eventTitle}>{event.title}</Text>
              <Text style={styles.eventDescription}>{event.description}</Text>
            </View>
          </View>
        ))}
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
  timeline: {
    paddingLeft: 20,
  },
  timelineItem: {
    marginBottom: 30,
    position: 'relative',
  },
  timelineLine: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: -30,
    width: 2,
    backgroundColor: '#ff69b4',
  },
  timelineDot: {
    position: 'absolute',
    left: -4,
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#ff69b4',
  },
  eventContent: {
    marginLeft: 20,
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 15,
    elevation: 2,
  },
  eventDate: {
    color: '#666',
    fontSize: 14,
    marginBottom: 5,
  },
  eventTitle: {
    color: '#ff69b4',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  eventDescription: {
    color: '#444',
    fontSize: 16,
    lineHeight: 22,
  },
}); 