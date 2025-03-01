import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated, Easing } from 'react-native';

export default function FlowerScreen() {
  // Animações para as pétalas
  const petalAnimations = Array(8).fill(0).map(() => useRef(new Animated.Value(0)).current);
  const centerAnimation = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Animação de rotação das pétalas
    const petalAnimationSequence = petalAnimations.map((anim, index) => {
      return Animated.sequence([
        Animated.delay(index * 200),
        Animated.timing(anim, {
          toValue: 1,
          duration: 1500,
          easing: Easing.elastic(1),
          useNativeDriver: true,
        })
      ]);
    });

    // Animação do centro da flor
    const centerAnimationSequence = Animated.timing(centerAnimation, {
      toValue: 1,
      duration: 2000,
      easing: Easing.elastic(1),
      useNativeDriver: true,
    });

    // Executar todas as animações
    Animated.parallel([...petalAnimationSequence, centerAnimationSequence]).start();
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.flowerContainer}>
        {/* Pétalas */}
        {petalAnimations.map((anim, index) => (
          <Animated.View
            key={`petal-${index}`}
            style={[
              styles.petal,
              {
                transform: [
                  { rotate: `${index * 45}deg` },
                  {
                    scale: anim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [0, 1]
                    })
                  }
                ]
              }
            ]}
          />
        ))}

        {/* Centro da flor */}
        <Animated.View
          style={[
            styles.center,
            {
              transform: [{
                scale: centerAnimation.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0, 1]
                })
              }]
            }
          ]}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
    justifyContent: 'center',
    alignItems: 'center',
  },
  flowerContainer: {
    width: 200,
    height: 200,
    justifyContent: 'center',
    alignItems: 'center',
  },
  petal: {
    position: 'absolute',
    width: 60,
    height: 60,
    backgroundColor: '#ff69b4',
    borderRadius: 30,
    transform: [{ translateY: -50 }],
  },
  center: {
    width: 40,
    height: 40,
    backgroundColor: '#ff1493',
    borderRadius: 20,
    elevation: 4,
  },
}); 