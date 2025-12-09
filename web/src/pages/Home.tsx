import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/layout';

interface TimeData {
  years: number;
  months: number;
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

const calculateTimeElapsed = (startDate: Date): TimeData => {
  const now = new Date();
  const diff = now.getTime() - startDate.getTime();
  
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const totalDays = Math.floor(hours / 24);
  const years = Math.floor(totalDays / 365);
  const months = Math.floor((totalDays % 365) / 30.44);
  const days = Math.floor(totalDays % 30.44);

  return {
    years,
    months,
    days,
    hours: hours % 24,
    minutes: minutes % 60,
    seconds: seconds % 60
  };
};

const Home = () => {
  const navigate = useNavigate();
  const [namoroTime, setNamoroTime] = useState<TimeData>({
    years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0
  });
  const [casamentoTime, setCasamentoTime] = useState<TimeData>({
    years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0
  });
  const [jadeTime, setJadeTime] = useState<TimeData>({
    years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0
  });

  useEffect(() => {
    const namoroDate = new Date('2024-10-12');
    const casamentoDate = new Date('2025-04-15');
    const jadeDate = new Date('2026-06-01'); // Assumindo início de junho
    
    const updateCounters = () => {
      setNamoroTime(calculateTimeElapsed(namoroDate));
      setCasamentoTime(calculateTimeElapsed(casamentoDate));
      setJadeTime(calculateTimeElapsed(jadeDate));
    };

    updateCounters();
    const timer = setInterval(updateCounters, 1000);
    return () => clearInterval(timer);
  }, []);

  const menuCards = [
    {
      title: 'Nossa História',
      description: 'Descubra como tudo começou e os momentos que nos trouxeram até aqui.',
      path: '/nossa-historia',
    },
    {
      title: 'Jogos do Amor 🎮',
      description: 'Divirta-se com nossos jogos especiais, incluindo o Quiz do Amor!',
      path: '/jogos',
    },
    {
      title: 'Mensagens do Coração',
      description: 'Palavras de amor e carinho que compartilhamos.',
      path: '/mensagens',
    },
    {
      title: 'Carta de Amor',
      description: 'Uma declaração especial do meu coração para você.',
      path: '/carta-de-amor',
    },
    {
      title: 'Uma Flor para Minha Esposa',
      description: 'Um jardim especial dedicado à mulher da minha vida 🌹',
      path: '/flor-para-esposa',
    },
  ];

  const renderCounter = (title: string, time: TimeData, icon: string) => (
    <Card className="bg-gradient-to-br from-love-primary to-love-primary-dark rounded-xl sm:rounded-2xl md:rounded-3xl p-3 sm:p-4 md:p-6 lg:p-8 shadow-lg my-4 sm:my-6 md:my-8 max-w-3xl mx-auto text-center transform transition-transform duration-300 hover:-translate-y-1">
      <CardHeader className="pb-1 sm:pb-2 md:pb-4">
        <CardTitle className="text-white text-lg sm:text-xl md:text-2xl lg:text-[1.8rem] mb-2 sm:mb-3 md:mb-4 font-semibold drop-shadow-md flex items-center justify-center gap-2">
          <span>{icon}</span>
          <span>{title}</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="px-2 sm:px-4">
        <div className="grid grid-cols-3 sm:grid-cols-3 md:grid-cols-6 gap-1.5 sm:gap-2 md:gap-3 lg:gap-4">
          {[
            { value: time.years, label: 'Anos' },
            { value: time.months, label: 'Meses' },
            { value: time.days, label: 'Dias' },
            { value: time.hours, label: 'Horas' },
            { value: time.minutes, label: 'Minutos' },
            { value: time.seconds, label: 'Segundos' },
          ].map((item, index) => (
            <div key={index} className="bg-white/90 rounded-lg sm:rounded-xl p-1.5 sm:p-2 md:p-3 lg:p-4">
              <div className="text-love-primary text-base sm:text-lg md:text-xl lg:text-2xl xl:text-[1.8rem] font-bold mb-0.5 sm:mb-1">
                {item.value}
              </div>
              <div className="text-love-primary-dark text-[10px] sm:text-xs md:text-sm lg:text-base">
                {item.label}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );

  return (
    <div className="w-full min-h-screen relative flex flex-col bg-gradient-to-b from-love-bg-start to-love-bg-end">
      <section className="w-full px-4 sm:px-6 lg:px-8 py-6 sm:py-8 lg:py-12 text-center relative z-10">
        <header className="max-w-4xl mx-auto mb-8 sm:mb-12">
          <h1 className="text-love-primary text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-[3.5rem] font-bold my-2 sm:my-4 md:my-6">
            Para Meu Amor <span className="text-[#ff1493]">❤️</span>
          </h1>
          
          {renderCounter('Começamos a Namorar', namoroTime, '💕')}
          {renderCounter('Nosso Casamento', casamentoTime, '💍')}
          {renderCounter('Nascimento da Jade', jadeTime, '👶')}
          
          <p className="text-love-primary-dark text-sm sm:text-base md:text-lg lg:text-xl xl:text-[1.4rem] max-w-2xl mx-auto mb-4 sm:mb-6 md:mb-8 leading-relaxed px-2 sm:px-4">
            Um jardim digital de memórias e amor, onde cada momento representa 
            uma parte especial da nossa história juntos.
          </p>
        </header>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-3 sm:gap-4 md:gap-6 max-w-7xl mx-auto px-4 sm:px-6 pb-8">
          {menuCards.map((card, index) => (
            <Card 
              key={index}
              className="flex flex-col justify-center items-center bg-white/90 p-3 sm:p-4 md:p-6 rounded-lg sm:rounded-xl md:rounded-2xl shadow-md backdrop-blur-sm cursor-pointer min-h-[140px] sm:min-h-[160px] md:min-h-[180px] transition-all duration-300 hover:-translate-y-1 hover:bg-white/95 hover:shadow-lg"
              onClick={() => navigate(card.path)}
            >
              <CardHeader className="p-0 pb-1 sm:pb-2">
                <CardTitle className="text-love-primary text-base sm:text-lg md:text-xl text-center font-medium">
                  {card.title}
                </CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <p className="text-gray-600 text-[11px] sm:text-xs md:text-sm text-center max-w-full mx-auto leading-snug">
                  {card.description}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>
    </div>
  );
};

export default Home;
