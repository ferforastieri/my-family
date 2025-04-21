import React, { useEffect, useState } from 'react';
import { View, Animated, StyleSheet, Dimensions } from 'react-native';

const { width, height } = Dimensions.get('window');

interface Flower {
  id: number;
  x: Animated.Value;
  y: Animated.Value;
  rotation: Animated.Value;
  scale: Animated.Value;
  emoji: string;
}

const flowerEmojis = ['🌸', '🌹', '🌺', '🌷', '💐', '🌼'];

export default function FallingFlowers() {
  const [flowers, setFlowers] = useState<Flower[]>([]);

  useEffect(() => {
    const createFlower = () => {
      const id = Date.now();
      const startX = Math.random() * width;
      const x = new Animated.Value(startX);
      const y = new Animated.Value(-50);
      const startRotation = Math.random() * 360;
      const rotation = new Animated.Value(startRotation);
      const scale = new Animated.Value(0.5 + Math.random() * 0.5);

      const flower: Flower = {
        id,
        x,
        y,
        rotation,
        scale,
        emoji: flowerEmojis[Math.floor(Math.random() * flowerEmojis.length)]
      };

      setFlowers(prev => [...prev, flower]);

      Animated.parallel([
        Animated.timing(y, {
          toValue: height + 50,
          duration: 5000 + Math.random() * 5000,
          useNativeDriver: true,
        }),
        Animated.timing(x, {
          toValue: startX + (Math.random() - 0.5) * 200,
          duration: 5000 + Math.random() * 5000,
          useNativeDriver: true,
        }),
        Animated.timing(rotation, {
          toValue: startRotation + 360,
          duration: 5000 + Math.random() * 5000,
          useNativeDriver: true,
        }),
      ]).start(() => {
        setFlowers(prev => prev.filter(f => f.id !== id));
      });
    };

    const interval = setInterval(createFlower, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <View style={StyleSheet.absoluteFill}>
      {flowers.map(flower => (
        <Animated.Text
          key={flower.id}
          style={[
            styles.flower,
            {
              transform: [
                { translateX: flower.x },
                { translateY: flower.y },
                { rotate: flower.rotation.interpolate({
                    inputRange: [0, 360],
                    outputRange: ['0deg', '360deg']
                  })
                },
                { scale: flower.scale }
              ]
            }
          ]}
        >
          {flower.emoji}
        </Animated.Text>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  flower: {
    position: 'absolute',
    fontSize: 24,
  },
}); 