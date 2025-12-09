import styled, { keyframes } from 'styled-components';

// Animações base
const sway = keyframes`
  0%, 100% { transform: rotate(-8deg); }
  50% { transform: rotate(8deg); }
`;

const float = keyframes`
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
`;

const growFlower = keyframes`
  0% { transform: scale(0) translateY(100%); }
  100% { transform: scale(1) translateY(0); }
`;

// Container do Jardim
const GardenContainer = styled.div`
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 60vh;
  background: linear-gradient(180deg, transparent 0%, rgba(255, 230, 240, 0.2) 100%);
  overflow: hidden;
  z-index: 1;
`;

// Base do Jardim (Grama e Terra)
// const GardenBase = styled.div`
//   position: absolute;
//   bottom: 0;
//   left: 0;
//   width: 100%;
//   height: 15%;
//   background: linear-gradient(
//     180deg,
//     #2d5a27 0%,
//     #1a3518 100%
//   );
//   &::before {
//     content: '';
//     position: absolute;
//     top: -20px;
//     left: 0;
//     width: 100%;
//     height: 30px;
//     background: repeating-linear-gradient(
//       45deg,
//       #2d5a27,
//       #2d5a27 10px,
//       #1a3518 10px,
//       #1a3518 20px
//     );
//   }
// `;

// Grupo de Flores
const FlowerBed = styled.div`
  position: absolute;
  bottom: 15%;
  left: 0;
  width: 100%;
  height: 85%;
  display: flex;
  justify-content: center;
  align-items: flex-end;
  gap: 30px;
  padding: 0 5%;
`;

// Flor Individual
const FlowerGroup = styled.div<{ $delay: number, $scale: number }>`
  position: relative;
  transform-origin: bottom center;
  animation: ${growFlower} 2s ${props => props.$delay}s backwards;
  scale: ${props => props.$scale};
  margin: 0 15px;
`;

// Caule Principal
const MainStem = styled.div`
  width: 8px;
  height: 200px;
  background: linear-gradient(to top, #2d5a27, #4a8b3f);
  position: relative;
  transform-origin: bottom center;
  animation: ${sway} 4s ease-in-out infinite;
  border-radius: 4px;
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 50%;
    width: 3px;
    height: 100%;
    background: rgba(255, 255, 255, 0.2);
    transform: translateX(-50%);
  }
`;

// Cabeça da Flor
const FlowerHead = styled.div`
  position: absolute;
  top: -40px;
  left: 50%;
  transform: translateX(-50%);
  width: 80px;
  height: 80px;
  animation: ${float} 3s ease-in-out infinite;
  
  &::after {
    content: '';
    position: absolute;
    bottom: -5px;
    left: 50%;
    transform: translateX(-50%);
    width: 8px;
    height: 15px;
    background: linear-gradient(to bottom, #4a8b3f, #2d5a27);
    border-radius: 4px;
  }
`;

// Pétalas
const PetalSet = styled.div`
  position: absolute;
  width: 100%;
  height: 100%;
  transform-origin: center;
`;

const Petal = styled.div<{ $petalColor: string }>`
  position: absolute;
  width: 35px;
  height: 50px;
  background: linear-gradient(to bottom, ${props => props.$petalColor}, #ffb6c1);
  border-radius: 50% 50% 50% 50%;
  transform-origin: bottom center;
  box-shadow: inset 0 0 10px rgba(0,0,0,0.2);
  
  &::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(
      to bottom,
      rgba(255,255,255,0.5),
      transparent
    );
    border-radius: inherit;
  }
`;

// Centro da Flor
const FlowerCenter = styled.div<{ $centerColor: string }>`
  width: 30px;
  height: 30px;
  background: ${props => props.$centerColor};
  border-radius: 50%;
  position: relative;
  z-index: 2;
  box-shadow: inset 0 0 10px rgba(0,0,0,0.3);
  
  &::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 80%;
    height: 80%;
    background: radial-gradient(
      circle,
      rgba(255,255,255,0.8),
      transparent 70%
    );
    border-radius: 50%;
  }
`;

// Folhas
const Leaf = styled.div<{ $side: 'left' | 'right', $position: number }>`
  position: absolute;
  width: 50px;
  height: 25px;
  background: linear-gradient(
    to ${props => props.$side},
    #4a8b3f,
    #69b05b
  );
  border-radius: 100% 0 100% 0;
  top: ${props => props.$position}%;
  ${props => props.$side}: -40px;
  transform-origin: ${props => props.$side === 'left' ? 'right' : 'left'} center;
  transform: rotate(${props => props.$side === 'left' ? '-30deg' : '30deg'});
  
  &::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: inherit;
    border-radius: inherit;
    filter: brightness(1.2);
    opacity: 0.3;
  }
`;

// Grama mais detalhada
const GrassBase = styled.div`
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 120px;
  background: linear-gradient(180deg, #2d5a27 0%, #1a3518 100%);
  
  &::before {
    content: '';
    position: absolute;
    top: -40px;
    left: 0;
    width: 100%;
    height: 60px;
    background: 
      repeating-linear-gradient(
        80deg,
        transparent 0px,
        transparent 2px,
        #2d5a27 2px,
        #2d5a27 4px
      ),
      repeating-linear-gradient(
        -80deg,
        transparent 0px,
        transparent 2px,
        #2d5a27 2px,
        #2d5a27 4px
      );
  }
`;

// Tufos de grama individuais
const GrassTuft = styled.div`
  position: absolute;
  bottom: 0;
  width: 15px;
  height: 40px;
  background: linear-gradient(to top, #2d5a27, #4a8b3f);
  clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
  transform-origin: bottom center;
  animation: ${sway} 2s ease-in-out infinite;
  
  &::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: inherit;
    filter: brightness(1.2);
    clip-path: polygon(30% 0%, 0% 100%, 60% 100%);
  }
`;

// Componente Principal
const FlowerAnimation = () => {
  const flowers = [
    { scale: 1, delay: 0, petalColor: '#ff69b4', centerColor: '#ffd700' },
    { scale: 0.8, delay: 0.3, petalColor: '#ff1493', centerColor: '#ffa500' },
    { scale: 1.2, delay: 0.6, petalColor: '#db7093', centerColor: '#ffd700' },
    { scale: 0.9, delay: 0.9, petalColor: '#ff69b4', centerColor: '#ffa500' },
    { scale: 1.1, delay: 1.2, petalColor: '#ff1493', centerColor: '#ffd700' },
    { scale: 0.85, delay: 1.5, petalColor: '#db7093', centerColor: '#ffa500' },
    { scale: 1.15, delay: 1.8, petalColor: '#ff69b4', centerColor: '#ffd700' },
    { scale: 0.95, delay: 2.1, petalColor: '#ff1493', centerColor: '#ffa500' }
  ];

  // Array de posições para os tufos de grama
  const grassPositions = Array.from({ length: 50 }, (_, i) => ({
    left: `${(i * 2)}%`,
    delay: Math.random() * 2,
    scale: 0.8 + Math.random() * 0.4
  }));

  return (
    <GardenContainer>
      <FlowerBed>
        {flowers.map((flower, index) => (
          <FlowerGroup key={index} $delay={flower.delay} $scale={flower.scale}>
            <FlowerHead>
              {[...Array(2)].map((_, setIndex) => (
                <PetalSet key={setIndex} style={{ transform: `rotate(${setIndex * 45}deg)` }}>
                  {[...Array(4)].map((_, petalIndex) => (
                    <Petal
                      key={petalIndex}
                      $petalColor={flower.petalColor}
                      style={{ transform: `rotate(${petalIndex * 90}deg) translateY(-25px)` }}
                    />
                  ))}
                </PetalSet>
              ))}
              <FlowerCenter $centerColor={flower.centerColor} />
            </FlowerHead>
            <MainStem>
              <Leaf $side="left" $position={30} />
              <Leaf $side="right" $position={50} />
              <Leaf $side="left" $position={70} />
            </MainStem>
          </FlowerGroup>
        ))}
      </FlowerBed>
      <GrassBase>
        {grassPositions.map((grass, index) => (
          <GrassTuft
            key={index}
            style={{
              left: grass.left,
              animationDelay: `${grass.delay}s`,
              scale: grass.scale,
              zIndex: Math.floor(Math.random() * 3)
            }}
          />
        ))}
      </GrassBase>
    </GardenContainer>
  );
};

export default FlowerAnimation; 