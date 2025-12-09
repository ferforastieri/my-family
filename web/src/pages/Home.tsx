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
  totalDays: number;
  isFuture: boolean;
}

const calculateTimeElapsed = (startDate: Date): TimeData & { totalDays: number; isFuture: boolean } => {
  const now = new Date();
  const diff = now.getTime() - startDate.getTime();
  const isFuture = diff < 0;
  const absDiff = Math.abs(diff);
  
  const seconds = Math.floor(absDiff / 1000);
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
    seconds: seconds % 60,
    totalDays,
    isFuture
  };
};

const Home = () => {
  const navigate = useNavigate();
  const [namoroTime, setNamoroTime] = useState<TimeData>({
    years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0, totalDays: 0, isFuture: false
  });
  const [casamentoTime, setCasamentoTime] = useState<TimeData>({
    years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0, totalDays: 0, isFuture: false
  });
  const [jadeTime, setJadeTime] = useState<TimeData>({
    years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0, totalDays: 0, isFuture: false
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

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric'
    });
  };

  const counterInfo = [
    {
      title: 'Começamos a Namorar',
      icon: '💕',
      date: new Date('2024-10-12'),
      message: 'Desde o primeiro olhar, sabia que você era especial',
      color: 'from-pink-400 to-pink-600'
    },
    {
      title: 'Nosso Casamento',
      icon: '💍',
      date: new Date('2025-04-15'),
      message: 'O dia mais feliz da minha vida ao seu lado',
      color: 'from-rose-400 to-rose-600'
    },
    {
      title: 'Nascimento da Jade',
      icon: '👶',
      date: new Date('2026-06-01'),
      message: 'Nosso maior presente de amor chegando',
      color: 'from-purple-400 to-purple-600'
    }
  ];

  const renderCounter = (info: typeof counterInfo[0], time: TimeData) => {
    return (
      <Card className={`bg-gradient-to-br ${info.color} rounded-xl p-4 sm:p-5 shadow-lg hover:shadow-xl transition-all duration-300 hover:-translate-y-1 border border-white/20 h-full flex flex-col`}>
        <CardHeader className="pb-3 flex-shrink-0">
          <div className="flex items-center justify-center gap-2 mb-2">
            <span className="text-2xl sm:text-3xl">{info.icon}</span>
            <CardTitle className="text-white text-base sm:text-lg font-bold">
              {info.title}
            </CardTitle>
          </div>
          <p className="text-white/90 text-xs sm:text-sm font-medium mb-2 min-h-[2rem]">
            {formatDate(info.date)}
          </p>
          <p className="text-white/80 text-[11px] sm:text-xs italic min-h-[2.5rem]">
            {info.message}
          </p>
        </CardHeader>
        <CardContent className="px-2 flex-1 flex flex-col justify-between">
          <div className="grid grid-cols-3 gap-2 sm:gap-3 mb-3">
            {[
              { value: Math.abs(time.years), label: 'Anos' },
              { value: Math.abs(time.months), label: 'Meses' },
              { value: Math.abs(time.days), label: 'Dias' },
            ].map((item, index) => (
              <div key={index} className="bg-white/95 rounded-lg p-2 sm:p-2.5 shadow-md">
                <div className="text-love-primary text-xl sm:text-2xl font-bold mb-1">
                  {item.value}
                </div>
                <div className="text-love-primary-dark text-[10px] sm:text-xs font-medium">
                  {item.label}
                </div>
              </div>
            ))}
          </div>
          <div className="bg-white/20 rounded-lg p-2 border border-white/30 mt-auto">
            <div className="text-white text-xs sm:text-sm font-semibold">
              {time.isFuture ? 'Faltam' : 'Já se passaram'}
            </div>
            <div className="text-white text-lg sm:text-xl font-bold">
              {time.totalDays} {time.totalDays === 1 ? 'dia' : 'dias'}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  };

  return (
    <div className="w-full min-h-screen relative flex flex-col bg-gradient-to-b from-love-bg-start to-love-bg-end">
      <section className="w-full px-4 sm:px-6 lg:px-8 py-6 sm:py-8 lg:py-12 text-center relative z-10">
        <header className="max-w-6xl mx-auto mb-6 sm:mb-8">
          <h1 className="text-love-primary text-2xl sm:text-3xl md:text-4xl font-bold my-4 sm:my-6">
            Para Meu Amor <span className="text-[#ff1493]">❤️</span>
          </h1>
          
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-5 mb-6 sm:mb-8 items-stretch">
            {renderCounter(counterInfo[0], namoroTime)}
            {renderCounter(counterInfo[1], casamentoTime)}
            {renderCounter(counterInfo[2], jadeTime)}
          </div>
          
          <p className="text-love-primary-dark text-sm sm:text-base max-w-2xl mx-auto mb-6 leading-relaxed px-2">
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
