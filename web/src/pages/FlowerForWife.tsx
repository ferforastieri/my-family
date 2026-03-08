import { useEffect } from 'react';

const FlowerForWife = () => {
  useEffect(() => {
    document.body.classList.remove('not-loaded');
    document.body.removeAttribute('style');
  }, []);

  return (
    <div className="min-h-screen flex flex-col items-center bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)] p-8 relative overflow-hidden">
      <h1 className="text-primary text-4xl md:text-5xl font-[Pacifico] text-center mb-8 z-[2] bg-gradient-to-r from-primary to-primary/80 bg-clip-text text-transparent animate-title-glow">
        Uma Flor para Meu Esposo
      </h1>
      <div className="absolute bottom-0 left-0 right-0 h-[80vh] w-full flex justify-center items-end">
        <div className="night"></div>
        <div className="flowers">
          <div className="flower flower--1">
            <div className="flower__leafs flower__leafs--1">
              <div className="flower__leaf flower__leaf--1"></div>
              <div className="flower__leaf flower__leaf--2"></div>
              <div className="flower__leaf flower__leaf--3"></div>
              <div className="flower__leaf flower__leaf--4"></div>
              <div className="flower__white-circle"></div>
            </div>
            <div className="flower__line">
              <div className="flower__line__leaf flower__line__leaf--1"></div>
              <div className="flower__line__leaf flower__line__leaf--2"></div>
              <div className="flower__line__leaf flower__line__leaf--3"></div>
              <div className="flower__line__leaf flower__line__leaf--4"></div>
            </div>
          </div>
          
          <div className="grow-ans" style={{ '--d': '1.2s' } as React.CSSProperties}>
            <div className="flower__g-long">
              <div className="flower__g-long__top"></div>
              <div className="flower__g-long__bottom"></div>
            </div>
          </div>
          
          <div className="growing-grass">
            <div className="flower__grass flower__grass--1">
              <div className="flower__grass--top"></div>
              <div className="flower__grass--bottom"></div>
              <div className="flower__grass__leaf flower__grass__leaf--1"></div>
              <div className="flower__grass__leaf flower__grass__leaf--2"></div>
              <div className="flower__grass__leaf flower__grass__leaf--3"></div>
              <div className="flower__grass__leaf flower__grass__leaf--4"></div>
              <div className="flower__grass__leaf flower__grass__leaf--5"></div>
              <div className="flower__grass__leaf flower__grass__leaf--6"></div>
              <div className="flower__grass__leaf flower__grass__leaf--7"></div>
              <div className="flower__grass__leaf flower__grass__leaf--8"></div>
              <div className="flower__grass__overlay"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FlowerForWife; 