import React from 'react';

const flowers = [
  { scale: 1, delay: 0, petalColor: '#ff69b4', centerColor: '#ffd700' },
  { scale: 0.8, delay: 0.3, petalColor: '#ff1493', centerColor: '#ffa500' },
  { scale: 1.2, delay: 0.6, petalColor: '#db7093', centerColor: '#ffd700' },
  { scale: 0.9, delay: 0.9, petalColor: '#ff69b4', centerColor: '#ffa500' },
  { scale: 1.1, delay: 1.2, petalColor: '#ff1493', centerColor: '#ffd700' },
  { scale: 0.85, delay: 1.5, petalColor: '#db7093', centerColor: '#ffa500' },
  { scale: 1.15, delay: 1.8, petalColor: '#ff69b4', centerColor: '#ffd700' },
  { scale: 0.95, delay: 2.1, petalColor: '#ff1493', centerColor: '#ffa500' },
];

const grassPositions = Array.from({ length: 50 }, (_, i) => ({
  left: `${i * 2}%`,
  delay: Math.random() * 2,
  scale: 0.8 + Math.random() * 0.4,
}));

const FlowerAnimation = () => {
  return (
    <div className="fixed bottom-0 left-0 w-full h-[60vh] bg-gradient-to-t from-[rgba(255,230,240,0.2)] to-transparent overflow-hidden z-[1]">
      <div className="absolute bottom-[15%] left-0 w-full h-[85%] flex justify-center items-end gap-6 px-[5%]">
        {flowers.map((flower, index) => (
          <div
            key={index}
            className="relative origin-bottom animate-grow-flower mx-4"
            style={{ animationDelay: `${flower.delay}s`, scale: flower.scale }}
          >
            <div className="absolute -top-10 left-1/2 -translate-x-1/2 w-20 h-20 animate-float">
              {[0, 45].map((rot, setIndex) => (
                <div key={setIndex} className="absolute w-full h-full origin-center" style={{ transform: `rotate(${rot}deg)` }}>
                  {[0, 90, 180, 270].map((petalRot, petalIndex) => (
                    <div
                      key={petalIndex}
                      className="absolute w-9 h-12 origin-bottom left-1/2 -translate-x-1/2 rounded-[50%] shadow-inner"
                      style={{
                        background: `linear-gradient(to bottom, ${flower.petalColor}, #ffb6c1)`,
                        transform: `rotate(${petalRot}deg) translateY(-25px)`,
                      }}
                    />
                  ))}
                </div>
              ))}
              <div
                className="absolute w-8 h-8 rounded-full z-[2] shadow-inner left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2"
                style={{ background: flower.centerColor }}
              />
            </div>
            <div className="w-2 h-[200px] bg-gradient-to-t from-[#2d5a27] to-[#4a8b3f] relative origin-bottom rounded animate-sway">
              <div className="absolute w-[50px] h-6 bg-gradient-to-r from-[#4a8b3f] to-[#69b05b] rounded-[100%_0_100%_0] -left-10 origin-right -rotate-30" style={{ top: '30%' }} />
              <div className="absolute w-[50px] h-6 bg-gradient-to-l from-[#4a8b3f] to-[#69b05b] rounded-[0_100%_0_100%] -right-10 origin-left rotate-30" style={{ top: '50%' }} />
              <div className="absolute w-[50px] h-6 bg-gradient-to-r from-[#4a8b3f] to-[#69b05b] rounded-[100%_0_100%_0] -left-10 origin-right -rotate-30" style={{ top: '70%' }} />
            </div>
          </div>
        ))}
      </div>
      <div className="absolute bottom-0 left-0 w-full h-[120px] bg-gradient-to-t from-[#1a3518] to-[#2d5a27]">
        {grassPositions.map((grass, index) => (
          <div
            key={index}
            className="absolute bottom-0 w-4 h-10 bg-gradient-to-t from-[#2d5a27] to-[#4a8b3f] origin-bottom animate-sway-fast"
            style={{
              left: grass.left,
              animationDelay: `${grass.delay}s`,
              scale: grass.scale,
              clipPath: 'polygon(50% 0%, 0% 100%, 100% 100%)',
              zIndex: Math.floor(Math.random() * 3),
            }}
          />
        ))}
      </div>
    </div>
  );
};

export default FlowerAnimation;
