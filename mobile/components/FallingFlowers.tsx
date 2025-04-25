import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import Animated, {
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withSequence,
  withDelay,
  Easing,
} from 'react-native-reanimated';

const { width, height } = Dimensions.get('window');

const FLOWERS = ['🌸', '🌹', '🌺', '🌻', '🌼', '🌷', '💐', '🏵️', '🥀', '🌱'];
const FLOWER_COLORS = ['#ff69b4', '#ff1493', '#ffc0cb', '#ffb6c1', '#db7093', '#ff69b4'];

interface Flower {
  id: number;
  emoji: string;
  color: string;
  size: number;
  x: number;
  y: number;
  rotation: number;
  delay: number;
  duration: number;
}

export default function FallingFlowers() {
  const [flowers, setFlowers] = useState<Flower[]>([]);

  useEffect(() => {
    const newFlowers: Flower[] = [];
    for (let i = 0; i < 30; i++) {
      newFlowers.push({
        id: i,
        emoji: FLOWERS[Math.floor(Math.random() * FLOWERS.length)],
        color: FLOWER_COLORS[Math.floor(Math.random() * FLOWER_COLORS.length)],
        size: Math.random() * 20 + 15,
        x: Math.random() * width,
        y: -50,
        rotation: Math.random() * 360,
        delay: Math.random() * 5000,
        duration: Math.random() * 5000 + 5000,
      });
    }
    setFlowers(newFlowers);
  }, []);

  return (
    <View style={styles.container}>
      {flowers.map((flower) => (
        <AnimatedFlower key={flower.id} flower={flower} />
      ))}
    </View>
  );
}

function AnimatedFlower({ flower }: { flower: Flower }) {
  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { translateY: withRepeat(withTiming(height + 50, { duration: flower.duration, easing: Easing.linear }), -1, false) },
        { translateX: withRepeat(withSequence(
          withTiming(flower.x + 50, { duration: flower.duration / 2 }),
          withTiming(flower.x - 50, { duration: flower.duration / 2 })
        ), -1, true) },
        { rotate: withRepeat(withTiming('360deg', { duration: flower.duration / 2 }), -1, false) },
      ],
    };
  });

  return (
    <Animated.View
      style={[
        styles.flower,
        {
          left: flower.x,
          top: flower.y,
          width: flower.size,
          height: flower.size,
        },
        animatedStyle,
      ]}
    >
      <Text style={[styles.flowerEmoji, { fontSize: flower.size }]}>
        {flower.emoji}
      </Text>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
  flower: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  flowerEmoji: {
    textShadowColor: 'rgba(0, 0, 0, 0.1)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
}); 