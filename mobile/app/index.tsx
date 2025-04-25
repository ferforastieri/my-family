import React from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, Dimensions } from 'react-native';
import { useRouter } from 'expo-router';
import FallingFlowers from '../components/FallingFlowers';
import TimeCounter from '../components/TimeCounter';

type RouteType = '/history' | '/games' | '/messages' | '/love-letter' | '/flower' | '/playlist';

interface MenuItem {
  title: string;
  icon: string;
  route: RouteType;
  description: string;
}

export default function HomeScreen() {
  const router = useRouter();
  const startDate = new Date('2024-10-15T00:00:00');
  const weddingDate = new Date('2026-01-01T00:00:00');

  const menuItems: MenuItem[] = [
    { title: 'Nossa História', icon: '📖', route: '/history', description: 'Como tudo começou...' },
    { title: 'Jogos do Amor', icon: '🎮', route: '/games', description: 'Quiz e diversão' },
    { title: 'Mensagens', icon: '💌', route: '/messages', description: 'Palavras do coração' },
    { title: 'Carta de Amor', icon: '💝', route: '/love-letter', description: 'Uma declaração especial' },
    { title: 'Flor para Esposa', icon: '🌹', route: '/flower', description: 'Um jardim de amor' },
    { title: 'Nossa Playlist', icon: '🎵', route: '/playlist', description: 'Nossas músicas' }
  ];

  return (
    <View style={styles.container}>
      <ScrollView>
        <View style={styles.header}>
          <Text style={styles.title}>Nossa História de Amor ❤️</Text>
          
          <TimeCounter
            title="Nosso Tempo Juntos"
            startDate={startDate}
            weddingDate={weddingDate}
          />

          <Text style={styles.subtitle}>
            Um jardim digital de memórias e amor, onde cada flor representa 
            um momento especial da nossa história juntos.
          </Text>
        </View>

        <View style={styles.menuGrid}>
          {menuItems.map((item, index) => (
            <TouchableOpacity
              key={item.route}
              style={styles.menuCard}
              onPress={() => router.push(item.route)}
            >
              <Text style={styles.menuIcon}>{item.icon}</Text>
              <Text style={styles.menuTitle}>{item.title}</Text>
              <Text style={styles.menuDescription}>{item.description}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>
      <View style={styles.flowersContainer}>
        <FallingFlowers />
      </View>
    </View>
  );
}

const { width } = Dimensions.get('window');
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
  },
  flowersContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1,
    pointerEvents: 'none',
  },
  header: {
    padding: 15,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#ff69b4',
    marginBottom: 15,
    textAlign: 'center',
  },
  weddingCard: {
    backgroundColor: '#d4488e',
  },
  subtitle: {
    color: '#d4488e',
    fontSize: 14,
    textAlign: 'center',
    marginHorizontal: 20,
    marginBottom: 15,
  },
  menuGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    padding: 10,
  },
  menuCard: {
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 15,
    width: width / 2 - 20,
    marginBottom: 15,
    alignItems: 'center',
    elevation: 2,
  },
  menuIcon: {
    fontSize: 24,
    marginBottom: 5,
  },
  menuTitle: {
    color: '#ff69b4',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 5,
  },
  menuDescription: {
    color: '#666',
    fontSize: 12,
    textAlign: 'center',
  },
});
