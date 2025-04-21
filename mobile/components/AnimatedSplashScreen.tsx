import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated, Dimensions, Easing } from 'react-native';
import LottieView from 'lottie-react-native';

const { width, height } = Dimensions.get('window');

interface AnimatedSplashScreenProps {
  onFinish: () => void;
}

export default function AnimatedSplashScreen({ onFinish }: AnimatedSplashScreenProps) {
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(0.5)).current;
  const heartBeatAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    // Animação de fade in e scale para o texto
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 1500,
        useNativeDriver: true,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 8,
        tension: 40,
        useNativeDriver: true,
      }),
    ]).start();

    // Animação de batimento cardíaco para o texto
    Animated.loop(
      Animated.sequence([
        Animated.timing(heartBeatAnim, {
          toValue: 1.1,
          duration: 500,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(heartBeatAnim, {
          toValue: 1,
          duration: 500,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.delay(1000),
      ])
    ).start();

    // Timer para chamar onFinish após a animação
    const timer = setTimeout(() => {
      onFinish();
    }, 4000); // 4 segundos de duração total

    return () => clearTimeout(timer);
  }, [fadeAnim, scaleAnim, heartBeatAnim, onFinish]);

  return (
    <View style={styles.container}>
      {/* Animação de flores usando Lottie */}
      <LottieView
        source={require('../assets/animations/flowers.json')}
        autoPlay
        loop={false}
        style={styles.lottieAnimation}
        onAnimationFinish={onFinish}
      />
      
      {/* Texto animado */}
      <Animated.View
        style={[
          styles.textContainer,
          {
            opacity: fadeAnim,
            transform: [
              { scale: scaleAnim },
              { scale: heartBeatAnim }
            ],
          },
        ]}
      >
        <Text style={styles.text}>Eu te amo,</Text>
        <Text style={styles.nameText}>Pessoa</Text>
        <Text style={styles.heartText}>❤️</Text>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ff69b4',
    justifyContent: 'center',
    alignItems: 'center',
  },
  lottieAnimation: {
    width: width * 0.8,
    height: height * 0.5,
  },
  textContainer: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    fontSize: 32,
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  nameText: {
    fontSize: 40,
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center',
    marginTop: 5,
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  heartText: {
    fontSize: 50,
    marginTop: 10,
  },
}); 