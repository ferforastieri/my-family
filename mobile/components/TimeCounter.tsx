import React from 'react';
import { View, Text, StyleSheet, Dimensions, ViewStyle } from 'react-native';

interface TimeCounterProps {
  title: string;
  startDate: Date;
  weddingDate: Date;
  style?: ViewStyle;
}

interface TimeUnitProps {
  value: number;
  label: string;
}

const TimeUnit = ({ value, label }: TimeUnitProps) => (
  <View style={styles.timeUnit}>
    <Text style={styles.timeNumber}>{value}</Text>
    <Text style={styles.timeLabel}>{label}</Text>
  </View>
);

export default function TimeCounter({ title, startDate, weddingDate, style }: TimeCounterProps) {
  const [time, setTime] = React.useState({
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  const [weddingTime, setWeddingTime] = React.useState({
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  });

  React.useEffect(() => {
    const updateCounter = () => {
      const now = new Date();
      
      // Relationship time (elapsed)
      const relationshipDiff = now.getTime() - startDate.getTime();
      const relationshipSeconds = Math.floor(relationshipDiff / 1000);
      const relationshipMinutes = Math.floor(relationshipSeconds / 60);
      const relationshipHours = Math.floor(relationshipMinutes / 60);
      const relationshipDays = Math.floor(relationshipHours / 24);
      const relationshipMonths = Math.floor(relationshipDays / 30.44);
      const relationshipYears = Math.floor(relationshipMonths / 12);

      setTime({
        years: relationshipYears,
        months: relationshipMonths % 12,
        days: relationshipDays % 30,
        hours: relationshipHours % 24,
        minutes: relationshipMinutes % 60,
        seconds: relationshipSeconds % 60
      });

      // Wedding time (elapsed)
      const weddingDiff = now.getTime() - weddingDate.getTime();
      const weddingSeconds = Math.floor(weddingDiff / 1000);
      const weddingMinutes = Math.floor(weddingSeconds / 60);
      const weddingHours = Math.floor(weddingMinutes / 60);
      const weddingDays = Math.floor(weddingHours / 24);
      const weddingMonths = Math.floor(weddingDays / 30.44);
      const weddingYears = Math.floor(weddingMonths / 12);

      setWeddingTime({
        years: weddingYears,
        months: weddingMonths % 12,
        days: weddingDays % 30,
        hours: weddingHours % 24,
        minutes: weddingMinutes % 60,
        seconds: weddingSeconds % 60
      });
    };

    const timer = setInterval(updateCounter, 1000);
    return () => clearInterval(timer);
  }, [startDate, weddingDate]);

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  return (
    <View style={[styles.countdownCard, style]}>
      <Text style={styles.countdownTitle}>{title}</Text>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Juntos desde:</Text>
        <Text style={styles.dateText}>{formatDate(startDate)}</Text>
        <View style={styles.timeGrid}>
          <TimeUnit value={time.years} label="Anos" />
          <TimeUnit value={time.months} label="Meses" />
          <TimeUnit value={time.days} label="Dias" />
          <TimeUnit value={time.minutes} label="Min" />
          <TimeUnit value={time.seconds} label="Seg" />
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Casados desde:</Text>
        <Text style={styles.dateText}>{formatDate(weddingDate)}</Text>
        <View style={styles.timeGrid}>
          <TimeUnit value={weddingTime.years} label="Anos" />
          <TimeUnit value={weddingTime.months} label="Meses" />
          <TimeUnit value={weddingTime.days} label="Dias" />
          <TimeUnit value={weddingTime.minutes} label="Min" />
          <TimeUnit value={weddingTime.seconds} label="Seg" />
        </View>
      </View>
    </View>
  );
}

const { width } = Dimensions.get('window');
const styles = StyleSheet.create({
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
    marginBottom: 15,
  },
  section: {
    marginBottom: 15,
  },
  sectionTitle: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 5,
  },
  dateText: {
    color: 'white',
    fontSize: 14,
    textAlign: 'center',
    marginBottom: 10,
    opacity: 0.9,
  },
  timeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    marginTop: 5,
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
}); 