import styled, { keyframes } from 'styled-components';

// Animações
const sway = keyframes`
  0%, 100% { transform: rotate(-8deg); }
  50% { transform: rotate(8deg); }
`;

const petalWave = (rotation: number) => keyframes`
  0%, 100% { 
    transform: rotate(${rotation}deg) translateX(50%) scale(1); 
  }
  50% { 
    transform: rotate(${rotation}deg) translateX(50%) scale(1.1); 
  }
`;

const growStem = keyframes`
  0% { height: 0; }
  100% { height: var(--stem-height); }
`;

const leafWave = keyframes`
  0%, 100% { transform: rotate(-5deg) scale(1); }
  50% { transform: rotate(5deg) scale(1.1); }
`;

// Componentes Estilizados
const GardenContainer = styled.div`
  position: absolute;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
  overflow: hidden;
`;

const FlowerContainer = styled.div<{ position: number }>`
  position: absolute;
  bottom: 0;
  left: ${({ position }) => position}%;
  transform-origin: bottom center;
  animation: ${sway} ${() => 3 + Math.random() * 2}s ease-in-out infinite;
  animation-delay: ${() => -Math.random() * 2}s;
  z-index: 1;
`;

const Flower = styled.div<{ size: number, color: string }>`
  position: relative;
  width: ${props => props.size}px;
  height: ${props => props.size}px;
  margin: 0 auto;
  transform-origin: center bottom;
  
  &::after {
    content: '';
    position: absolute;
    bottom: -5px;
    left: 50%;
    transform: translateX(-50%);
    width: 8px;
    height: 10px;
    background: linear-gradient(to bottom, ${props => props.color}, #4a8b3f);
    border-radius: 4px;
    z-index: 2;
  }
`;

const PetalContainer = styled.div`
  position: absolute;
  width: 100%;
  height: 100%;
  transform-origin: center center;
`;

const Petal = styled.div<{ rotation: number, color: string }>`
  position: absolute;
  width: 45%;
  height: 45%;
  top: 27.5%;
  left: 27.5%;
  background: ${props => props.color};
  border-radius: 50% 50% 50% 0;
  transform-origin: center center;
  transform: rotate(${props => props.rotation}deg) translateX(50%);
  animation: ${props => petalWave(props.rotation)} 3s ease-in-out infinite;
  animation-delay: ${props => props.rotation * 0.1}s;
  will-change: transform;
  
  &::before {
    content: '';
    position: absolute;
    width: 100%;
    height: 100%;
    background: inherit;
    border-radius: inherit;
    filter: brightness(1.2);
    opacity: 0.7;
    transform: scale(0.9);
  }

  &::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 50%;
    width: 40%;
    height: 20%;
    background: inherit;
    filter: brightness(0.8);
    transform: translateX(-50%) rotate(-45deg);
    border-radius: 0 0 50% 50%;
  }
`;

const FlowerCenter = styled.div<{ size: number, letter?: string }>`
  position: absolute;
  width: ${({ size }) => size * 0.35}px;
  height: ${({ size }) => size * 0.35}px;
  background: #ffd700;
  border-radius: 50%;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  box-shadow: inset 0 0 10px rgba(0,0,0,0.2);
  z-index: 3;
  
  &::after {
    content: '${({ letter }) => letter || ""}';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-family: 'Pacifico', cursive;
    font-size: ${({ size }) => size * 0.2}px;
    color: #d4488e;
    text-shadow: 1px 1px 1px rgba(0,0,0,0.2);
    width: 100%;
    text-align: center;
    line-height: 1;
  }
`;

const Stem = styled.div<{ height: number }>`
  --stem-height: ${({ height }) => height}px;
  width: 8px;
  height: 0;
  background: linear-gradient(to top, 
    #2d5a27,
    #4a8b3f
  );
  position: relative;
  margin: 0 auto;
  animation: ${growStem} 2s ease-out forwards;
  border-radius: 4px;
  z-index: 1;
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 50%;
    transform: translateX(-50%);
    width: 12px;
    height: 15px;
    background: inherit;
    border-radius: 6px;
  }
`;

const Leaf = styled.div<{ side: 'left' | 'right', position: number }>`
  position: absolute;
  width: 30px;
  height: 15px;
  background: linear-gradient(to ${({ side }) => side}, 
    #4a8b3f,
    #69b05b
  );
  border-radius: 100% 0 100% 0;
  top: ${({ position }) => position}%;
  ${({ side }) => side}: -20px;
  transform-origin: ${({ side }) => side === 'left' ? 'right' : 'left'} center;
  animation: ${leafWave} 3s ease-in-out infinite;
  animation-delay: ${() => -Math.random() * 2}s;

  &::after {
    content: '';
    position: absolute;
    width: 100%;
    height: 100%;
    background: inherit;
    border-radius: inherit;
    filter: brightness(1.2);
    opacity: 0.7;
  }
`;

// Adicione um novo componente para pétalas em forma de coração
const HeartPetal = styled(Petal)`
  border-radius: 50% 0;
  transform-origin: bottom right;
  
  &::before {
    border-radius: 50% 0;
  }
  
  &::after {
    border-radius: 50% 0;
  }
`;

interface FlowerProps {
  position: number;
  size: number;
  stemHeight: number;
  color: string;
  type?: 'regular' | 'heart';
  letter?: string;
}

const SingleFlower = ({ position, size, stemHeight, color, type = 'regular', letter = '' }: FlowerProps) => {
  const petalCount = type === 'regular' ? 8 : 6;
  const petals = Array.from({ length: petalCount }, (_, i) => ({
    rotation: (i * 360) / petalCount,
  }));

  return (
    <FlowerContainer position={position}>
      <Flower size={size} color={color}>
        <PetalContainer>
          {petals.map((petal, index) => (
            type === 'regular' ? (
              <Petal key={index} rotation={petal.rotation} color={color} />
            ) : (
              <HeartPetal key={index} rotation={petal.rotation} color={color} />
            )
          ))}
        </PetalContainer>
        <FlowerCenter size={size} letter={letter} />
      </Flower>
      <Stem height={stemHeight}>
        <Leaf side="left" position={30} />
        <Leaf side="right" position={60} />
        <Leaf side="left" position={80} />
      </Stem>
    </FlowerContainer>
  );
};

const FlowerGarden = () => {
  const nameFlowers: FlowerProps[] = [
    // M
    { position: 5, size: 120, stemHeight: 300, color: '#ff69b4', type: 'regular', letter: 'M' },
    // I
    { position: 11, size: 115, stemHeight: 290, color: '#ff1493', type: 'heart', letter: 'I' },
    // R
    { position: 17, size: 120, stemHeight: 300, color: '#db7093', type: 'regular', letter: 'R' },
    // I
    { position: 23, size: 115, stemHeight: 290, color: '#ff69b4', type: 'heart', letter: 'I' },
    // A
    { position: 29, size: 120, stemHeight: 300, color: '#ff1493', type: 'regular', letter: 'A' },
    // M
    { position: 35, size: 120, stemHeight: 300, color: '#db7093', type: 'heart', letter: 'M' },
    // &
    { position: 43, size: 125, stemHeight: 310, color: '#ff69b4', type: 'regular', letter: '&' },
    // F
    { position: 51, size: 120, stemHeight: 300, color: '#ff1493', type: 'heart', letter: 'F' },
    // E
    { position: 57, size: 115, stemHeight: 290, color: '#db7093', type: 'regular', letter: 'E' },
    // R
    { position: 63, size: 120, stemHeight: 300, color: '#ff69b4', type: 'heart', letter: 'R' },
    // N
    { position: 69, size: 120, stemHeight: 300, color: '#ff1493', type: 'regular', letter: 'N' },
    // A
    { position: 75, size: 115, stemHeight: 290, color: '#db7093', type: 'heart', letter: 'A' },
    // N
    { position: 81, size: 120, stemHeight: 300, color: '#ff69b4', type: 'regular', letter: 'N' },
    // D
    { position: 87, size: 115, stemHeight: 290, color: '#ff1493', type: 'heart', letter: 'D' },
    // O
    { position: 93, size: 120, stemHeight: 300, color: '#db7093', type: 'regular', letter: 'O' },
  ];

  const decorativeFlowers: FlowerProps[] = Array.from({ length: 8 }, (): FlowerProps => {
    const flowerType: 'regular' | 'heart' = Math.random() > 0.5 ? 'regular' : 'heart';
    return {
      position: Math.random() * 95,
      size: 50 + Math.random() * 30,
      stemHeight: 220 + Math.random() * 100,
      color: `hsl(${330 + Math.random() * 30}, 80%, ${70 + Math.random() * 10}%)`,
      type: flowerType,
      letter: ''
    };
  });

  const allFlowers = [...nameFlowers, ...decorativeFlowers];

  return (
    <GardenContainer>
      {allFlowers.map((flower, index) => (
        <SingleFlower key={index} {...flower} />
      ))}
    </GardenContainer>
  );
};

export default FlowerGarden; 