import React, { useEffect, useState } from 'react';
import { View, StyleSheet, Animated, Easing, Dimensions, Text } from 'react-native';

const { width, height } = Dimensions.get('window');

interface Flower {
  id: number;
  growth: Animated.Value;
  rotation: Animated.Value;
  petalGrowth: Animated.Value[];
}

export default function FlowerScreen() {
  const [flowers, setFlowers] = useState<Flower[]>([]);
  const weddingDate = new Date('2026-01-01');
  const now = new Date();
  const monthsMarried = Math.max(0,
    (now.getFullYear() - weddingDate.getFullYear()) * 12 + 
    (now.getMonth() - weddingDate.getMonth())
  );

  useEffect(() => {
    // Limitar a 12 flores e garantir pelo menos 1
    const flowerCount = Math.min(Math.max(monthsMarried, 1), 12);
    const newFlowers: Flower[] = [];

    for (let i = 0; i < flowerCount; i++) {
      newFlowers.push({
        id: i,
        growth: new Animated.Value(0),
        rotation: new Animated.Value(0),
        petalGrowth: Array(8).fill(0).map(() => new Animated.Value(0))
      });
    }

    setFlowers(newFlowers);

    newFlowers.forEach((flower, index) => {
      const delay = index * 300; // Reduzindo o delay entre flores

      // Crescimento mais suave da flor
      Animated.sequence([
        Animated.delay(delay),
        Animated.spring(flower.growth, {
          toValue: 1,
          tension: 30, // Reduzindo a tensão para crescimento mais suave
          friction: 7,  // Aumentando a fricção para menos bounce
          useNativeDriver: true
        })
      ]).start();

      // Rotação mais sutil
      Animated.loop(
        Animated.sequence([
          Animated.timing(flower.rotation, {
            toValue: 1,
            duration: 4000,
            easing: Easing.inOut(Easing.sin),
            useNativeDriver: true
          }),
          Animated.timing(flower.rotation, {
            toValue: -1,
            duration: 4000,
            easing: Easing.inOut(Easing.sin),
            useNativeDriver: true
          })
        ])
      ).start();

      // Pétalas com crescimento mais suave
      flower.petalGrowth.forEach((petal, petalIndex) => {
        Animated.sequence([
          Animated.delay(delay + petalIndex * 50), // Reduzindo delay entre pétalas
          Animated.spring(petal, {
            toValue: 1,
            tension: 30,
            friction: 7,
            useNativeDriver: true
          })
        ]).start();
      });
    });
  }, [monthsMarried]);

  const renderFlower = (flower: Flower) => {
    const rotation = flower.rotation.interpolate({
      inputRange: [-1, 1],
      outputRange: ['-3deg', '3deg']
    });

    const scale = flower.growth.interpolate({
      inputRange: [0, 1],
      outputRange: [0, 1]
    });

    // Função para gerar pontos do coração
    const getHeartPosition = (index: number, total: number): { x: number; y: number } => {
      // Parâmetro t vai de 0 a 2PI
      const t = (index / total) * 2 * Math.PI;
      
      // Equações paramétricas do coração
      // x = 16sin³(t)
      // y = 13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t)
      const heartX = 16 * Math.pow(Math.sin(t), 3);
      const heartY = 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t);
      
      // Ajustando a escala e posição
      return {
        x: width * 0.5 + (heartX * width * 0.02),
        y: 100 + (heartY * 3)
      };
    };

    // Calculando posição baseada no índice
    let xPos: number;
    let yPos: number;

    if (flower.id === 0) {
      // Primeira flor no centro do coração
      xPos = width * 0.5;
      yPos = 80;
    } else {
      // Demais flores formando o contorno do coração
      const position = getHeartPosition(flower.id, 12);
      xPos = position.x;
      yPos = position.y;
    }

    return (
      <Animated.View
        key={flower.id}
        style={[
          styles.flowerContainer,
          {
            transform: [
              { scale },
              { rotate: rotation }
            ],
            left: xPos - 50,
            bottom: yPos
          }
        ]}
      >
        {/* Caule */}
        <View style={styles.stem} />

        {/* Pétalas */}
        {flower.petalGrowth.map((petal, index) => (
          <Animated.View
            key={`petal-${flower.id}-${index}`}
            style={[
              styles.petal,
              {
                transform: [
                  { rotate: `${index * 45}deg` },
                  { scale: petal }
                ]
              }
            ]}
          />
        ))}

        {/* Centro da Flor - agora sem animação */}
        <View style={styles.flowerCenter} />
      </Animated.View>
    );
  };

  const renderSunRays = () => {
    return Array.from({ length: 12 }).map((_, i) => (
      <View
        key={`sun-ray-${i}`}
        style={[
          styles.sunRay,
          {
            transform: [
              { rotate: `${i * 30}deg` },
              { translateY: -35 }
            ]
          }
        ]}
      />
    ));
  };

  return (
    <View style={styles.container}>
      <View style={styles.sky}>
        {/* Sol */}
        <View style={styles.sun}>
          {renderSunRays()}
          <View style={styles.sunInner} />
        </View>
        
        {/* Nuvem */}
        <View style={styles.cloudWrapper}>
          {/* Forma da nuvem */}
          <View style={styles.cloudCenter} />
          <View style={[styles.cloudPart, styles.cloudTop]} />
          <View style={[styles.cloudPart, styles.cloudLeft]} />
          <View style={[styles.cloudPart, styles.cloudRight]} />
          
          {/* Mensagem flutuando na nuvem */}
          <Text style={styles.message}>
            Nosso jardim cresce com o nosso amor ❤️
          </Text>
        </View>
      </View>

      <View style={styles.garden}>
        {/* Detalhes do chão */}
        <View style={styles.groundDetails}>
          {/* Grama de fundo */}
          {Array.from({ length: 20 }).map((_, i) => (
            <View key={`grass-back-${i}`} style={[
              styles.grassBlade,
              {
                left: `${i * 5}%`,
                height: 15 + Math.random() * 10,
                transform: [{ rotate: `${-10 + Math.random() * 20}deg` }]
              }
            ]} />
          ))}
          
          {/* Grama da frente (mais escura) */}
          {Array.from({ length: 15 }).map((_, i) => (
            <View key={`grass-front-${i}`} style={[
              styles.grassBladeFront,
              {
                left: `${i * 7}%`,
                height: 20 + Math.random() * 15,
                transform: [{ rotate: `${-15 + Math.random() * 30}deg` }]
              }
            ]} />
          ))}
        </View>
        
        {flowers.map(renderFlower)}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#87CEEB', // Céu azul claro
  },
  sky: {
    height: 180,
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  sun: {
    position: 'absolute',
    right: 20,
    top: 20,
    width: 70,
    height: 70,
    borderRadius: 35,
    backgroundColor: '#FFD700',
    shadowColor: '#FFD700',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.5,
    shadowRadius: 15,
    elevation: 5,
  },
  sunInner: {
    position: 'absolute',
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#FFA500',
    top: 5,
    left: 5,
  },
  sunRay: {
    position: 'absolute',
    width: 4,
    height: 30,
    backgroundColor: '#FFD700',
    left: '50%',
    top: '50%',
    marginLeft: -2,
    marginTop: -15,
  },
  cloudWrapper: {
    width: '75%',
    height: 100,
    alignSelf: 'flex-start',
    marginTop: 20,
    marginLeft: -10,
    position: 'relative',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cloudCenter: {
    position: 'absolute',
    width: '100%',
    height: 60,
    backgroundColor: 'white',
    borderRadius: 30,
  },
  cloudPart: {
    position: 'absolute',
    backgroundColor: 'white',
    borderRadius: 50,
  },
  cloudTop: {
    width: '70%',
    height: 60,
    top: -15,
  },
  cloudLeft: {
    width: 50,
    height: 50,
    left: '5%',
    top: 5,
  },
  cloudRight: {
    width: 50,
    height: 50,
    right: '5%',
    top: 5,
  },
  message: {
    fontSize: 12,
    color: '#FF69B4',
    textAlign: 'center',
    fontWeight: 'bold',
    lineHeight: 16,
    zIndex: 2,
    paddingHorizontal: 10,
  },
  garden: {
    flex: 1,
    backgroundColor: '#228B22',
    position: 'relative',
    paddingBottom: 20,
  },
  groundDetails: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 40,
    overflow: 'hidden',
    backgroundColor: '#1a6b1a' // Base mais escura
  },
  grassBlade: {
    position: 'absolute',
    bottom: -5,
    width: 4,
    backgroundColor: '#2d912d',
    borderTopLeftRadius: 2,
    borderTopRightRadius: 2
  },
  grassBladeFront: {
    position: 'absolute',
    bottom: -5,
    width: 5,
    backgroundColor: '#1f7a1f',
    borderTopLeftRadius: 3,
    borderTopRightRadius: 3,
    zIndex: 2
  },
  flowerContainer: {
    position: 'absolute',
    alignItems: 'center',
    width: 100,
    height: 200
  },
  stem: {
    width: 4,
    height: 120,
    backgroundColor: '#2E8B57',
    position: 'absolute',
    bottom: 0
  },
  petal: {
    position: 'absolute',
    width: 30,
    height: 50,
    backgroundColor: '#FF69B4',
    borderRadius: 25,
    top: 0,
    left: 35,
    transformOrigin: 'center bottom'
  },
  flowerCenter: {
    position: 'absolute',
    width: 30,
    height: 30,
    backgroundColor: '#FFD700',
    borderRadius: 15,
    top: 35,
    shadowColor: '#FFD700',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.5,
    shadowRadius: 5,
    elevation: 3
  },
}); 