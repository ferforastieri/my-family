import React from 'react';
import { View, Text, StyleSheet, Dimensions, ViewStyle } from 'react-native';

interface TimeCounterProps {
  title: string;
  startDate: Date;
  endDate?: Date;
  isCountdown?: boolean;
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

export default function TimeCounter({ title, startDate, endDate, isCountdown = false, style }: TimeCounterProps) {
  const [time, setTime] = React.useState({
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
      const diff = isCountdown && endDate
        ? now.getTime() - endDate.getTime()
        : now.getTime() - startDate.getTime();
      
      const seconds = Math.floor(diff / 1000);
      const minutes = Math.floor(seconds / 60);
      const hours = Math.floor(minutes / 60);
      const days = Math.floor(hours / 24);
      const months = Math.floor(days / 30.44);
      const years = Math.floor(months / 12);

      setTime({
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
  }, [startDate, endDate, isCountdown]);

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
      <Text style={styles.dateText}>
        Data Inicial: {formatDate(startDate)}
      </Text>
      <View style={styles.timeGrid}>
        <TimeUnit value={time.years} label="Anos" />
        <TimeUnit value={time.months} label="Meses" />
        <TimeUnit value={time.days} label="Dias" />
        <TimeUnit value={time.hours} label="Horas" />
        <TimeUnit value={time.minutes} label="Min" />
        <TimeUnit value={time.seconds} label="Seg" />
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
}); 