import { useMemo, useCallback } from 'react';
import styled from 'styled-components';

// Animações




// Componentes Estilizados
const GardenContainer = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100vh;
  overflow: hidden;
  pointer-events: none;
  z-index: 0;
`;

interface FlowerProps {
  size: number;
  left: string;
  delay: number;
  color: string;
  startPosition: number;
  isSpecial?: boolean;
  letter?: string;
}

const Flower = styled.div<FlowerProps>`
  position: fixed;
  width: ${props => props.size}px;
  height: ${props => props.size}px;
  left: ${props => props.left};
  top: ${props => props.startPosition}%;
  animation: float ${props => 8 + props.delay}s linear infinite;
  transform-origin: center;
  z-index: ${props => props.isSpecial ? 1 : 0};

  @keyframes float {
    0% {
      transform: translateY(0) rotate(0deg);
      opacity: 0;
    }
    10% {
      opacity: 1;
    }
    90% {
      opacity: 1;
    }
    100% {
      transform: translateY(-120vh) rotate(360deg);
      opacity: 0;
    }
  }

  &::before {
    content: ${props => `'${props.letter || "🌸"}'`};
    font-size: ${props => props.size}px;
    color: ${props => props.color};
    position: absolute;
    top: 0;
    left: 0;
    font-family: 'Pacifico', cursive;
    text-shadow: ${props => props.isSpecial ? '2px 2px 4px rgba(0,0,0,0.2)' : 'none'};
  }
`;






// Adicione um novo componente para pétalas em forma de coração

interface FlowerConfig extends FlowerProps {
  startDelay: number;
}

const FlowerGarden = () => {
  const flowers = useMemo(() => {
    const hoje = new Date().toISOString().split('T')[0];
    const seed = hoje.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
    
    const seededRandom = (min: number, max: number, index: number) => {
      const x = Math.sin(seed + index) * 10000;
      return min + (x - Math.floor(x)) * (max - min);
    };

    const flowerEmojis = ['🌸', '🌹', '🌺', '🌻', '🌼', '🌷', '💐', '🏵️'];
    const colors = [
      '#FF69B4', // Rosa claro
      '#FF1493', // Rosa escuro
      '#9400D3', // Violeta
      '#FF4500', // Laranja avermelhado
      '#FFD700', // Amarelo
      '#00FF7F', // Verde primavera
      '#87CEEB', // Azul céu
      '#DDA0DD', // Lilás
      '#FF6347', // Tomate
      '#4169E1'  // Azul real
    ];

    // Criar nome em posição aleatória
    const nomes = "MIRIAM❤️E❤️FERNANDO";
    const startLeft = seededRandom(5, 70, 0); // Posição horizontal aleatória
    const startTop = seededRandom(20, 80, 100); // Posição vertical aleatória
    
    const letrasEspeciais = nomes.split('').map((letra, i) => ({
      size: 35,
      left: `${startLeft + (i * 2.5)}%`,
      delay: 0.5,
      color: letra === '❤️' ? '#ff0000' : '#FF1493',
      startDelay: i * 0.1,
      startPosition: startTop,
      isSpecial: true,
      letter: letra
    }));

    // Criar flores normais mais coloridas
    const floresNormais = Array.from({ length: 40 }, (_, i) => {
      const isHeart = seededRandom(0, 1, i) < 0.3;
      const flowerIndex = Math.floor(seededRandom(0, flowerEmojis.length, i + 700));
      
      return {
        size: isHeart ? seededRandom(20, 30, i) : seededRandom(15, 25, i),
        left: `${seededRandom(0, 100, i + 100)}%`,
        delay: seededRandom(0, 4, i + 200),
        color: colors[Math.floor(seededRandom(0, colors.length, i + 300))],
        startDelay: seededRandom(0, 8, i + 400),
        startPosition: seededRandom(0, 120, i + 500),
        isSpecial: isHeart,
        letter: isHeart ? '❤️' : flowerEmojis[flowerIndex]
      };
    });

    return [...letrasEspeciais, ...floresNormais];
  }, []);

  const renderFlower = useCallback((config: FlowerConfig, index: number) => (
    <Flower
      key={`flower-${index}`}
      size={config.size}
      left={config.left}
      delay={config.delay}
      color={config.color}
      startPosition={config.startPosition}
      isSpecial={config.isSpecial}
      letter={config.letter}
      style={{
        animationDelay: `-${config.startDelay}s`
      }}
    />
  ), []);

  return (
    <GardenContainer>
      {flowers.map((flower, index) => renderFlower(flower, index))}
    </GardenContainer>
  );
};

export default FlowerGarden; 