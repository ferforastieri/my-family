import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet, Dimensions } from 'react-native';
import { useRouter } from 'expo-router';
import FallingFlowers from '../components/FallingFlowers';

type RouteType = '/history' | '/games' | '/messages' | '/love-letter' | '/flower' | '/playlist';

interface MenuItem {
  title: string;
  icon: string;
  route: RouteType;
  description: string;
}

export default function HomeScreen() {
  const router = useRouter();
  const [timeElapsed, setTimeElapsed] = useState({
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  useEffect(() => {
    const startDate = new Date('2024-10-15T00:00:00');
    
    const updateCounter = () => {
      const now = new Date();
      const diff = now.getTime() - startDate.getTime();
      
      const seconds = Math.floor(diff / 1000);
      const minutes = Math.floor(seconds / 60);
      const hours = Math.floor(minutes / 60);
      const days = Math.floor(hours / 24);
      const months = Math.floor(days / 30.44);
      const years = Math.floor(months / 12);

      setTimeElapsed({
        years,
        months: months % 12,
        days: days % 30,
        hours: hours % 24,
        minutes: minutes % 60,
        seconds: seconds % 60
      });
    };

    const timer = setInterval(updateCounter, 1000);
    return () => clearInterval(timer);
  }, []);

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
      <FallingFlowers />
      <ScrollView>
        <View style={styles.header}>
          <Text style={styles.title}>Para Meu Amor ❤️</Text>
          
          <View style={styles.countdownCard}>
            <Text style={styles.countdownTitle}>Nosso Amor em Números</Text>
            <View style={styles.timeGrid}>
              <TimeUnit value={timeElapsed.years} label="Anos" />
              <TimeUnit value={timeElapsed.months} label="Meses" />
              <TimeUnit value={timeElapsed.days} label="Dias" />
              <TimeUnit value={timeElapsed.hours} label="Horas" />
              <TimeUnit value={timeElapsed.minutes} label="Min" />
              <TimeUnit value={timeElapsed.seconds} label="Seg" />
            </View>
          </View>

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
    </View>
  );
}

const TimeUnit = ({ value, label }: { value: number; label: string }) => (
  <View style={styles.timeUnit}>
    <Text style={styles.timeNumber}>{value}</Text>
    <Text style={styles.timeLabel}>{label}</Text>
  </View>
);

const { width } = Dimensions.get('window');
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
  },
  header: {
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#ff69b4',
    marginBottom: 20,
    textAlign: 'center',
  },
  countdownCard: {
    backgroundColor: '#ff69b4',
    borderRadius: 15,
    padding: 15,
    width: '100%',
    marginBottom: 20,
    elevation: 3,
  },
  countdownTitle: {
    color: 'white',
    fontSize: 20,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  timeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    marginTop: 10,
  },
  timeUnit: {
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 8,
    minWidth: width / 6 - 10,
    alignItems: 'center',
    margin: 2,
  },
  timeNumber: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#ff69b4',
  },
  timeLabel: {
    fontSize: 12,
    color: '#d4488e',
  },
  subtitle: {
    color: '#d4488e',
    fontSize: 16,
    textAlign: 'center',
    marginHorizontal: 20,
    marginBottom: 20,
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
