import React, { useEffect, useRef, useState } from 'react';

declare global {
  interface Window {
    YT: any;
    onYouTubeIframeAPIReady: () => void;
  }
}

interface YouTubePlayerProps {
  youtubeUrl: string;
}

export const YouTubePlayer: React.FC<YouTubePlayerProps> = ({ youtubeUrl }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<any>(null);
  const [error, setError] = useState(false);

  const getVideoId = (url: string): string => {
    try {
      const match = url.match(/(?:youtu\.be\/|youtube\.com(?:\/embed\/|\/v\/|\/watch\?v=|\/watch\?.+&v=))([^?&]+)/);
      return match ? match[1] : '';
    } catch {
      return '';
    }
  };

  useEffect(() => {
    const videoId = getVideoId(youtubeUrl);
    console.log('Video ID extraído:', videoId);

    if (!videoId) {
      setError(true);
      return;
    }

    if (playerRef.current) {
      playerRef.current.destroy();
      playerRef.current = null;
    }

    const playerElement = document.createElement('div');
    playerElement.id = `youtube-player-${videoId}`;
    
    if (containerRef.current) {
      containerRef.current.innerHTML = '';
      containerRef.current.appendChild(playerElement);
    }

    const initPlayer = () => {
      try {
        playerRef.current = new window.YT.Player(playerElement.id, {
          videoId: videoId,
          host: 'https://www.youtube-nocookie.com',
          playerVars: {
            autoplay: 0,
            modestbranding: 1,
            rel: 0,
            showinfo: 1,
            origin: window.location.origin,
            widget_referrer: window.location.href,
            enablejsapi: 1,
            playsinline: 1
          },
          events: {
            onError: (event: any) => {
              console.error('Erro no player do YouTube:', event.data);
              switch (event.data) {
                case 2:
                  console.error('ID do vídeo inválido');
                  break;
                case 5:
                  console.error('Erro HTML5');
                  break;
                case 100:
                  console.error('Vídeo não encontrado');
                  break;
                case 101:
                case 150:
                  console.error('Vídeo não permite incorporação');
                  break;
                default:
                  console.error('Erro desconhecido');
              }
              setError(true);
            },
            onReady: (event: any) => {
              console.log('Player pronto');
              setError(false);
              try {
                event.target.playVideo();
              } catch (err) {
                console.error('Erro ao iniciar o vídeo:', err);
              }
            },
          },
        });
      } catch (err) {
        console.error('Erro ao inicializar o player:', err);
        setError(true);
      }
    };

    if (window.YT && window.YT.Player) {
      initPlayer();
    } else {
      const tag = document.createElement('script');
      tag.src = 'https://www.youtube.com/iframe_api';
      const firstScriptTag = document.getElementsByTagName('script')[0];
      firstScriptTag.parentNode?.insertBefore(tag, firstScriptTag);

      window.onYouTubeIframeAPIReady = initPlayer;
    }

    return () => {
      if (playerRef.current?.destroy) {
        playerRef.current.destroy();
        playerRef.current = null;
      }
    };
  }, [youtubeUrl]);

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center p-5 bg-muted dark:bg-muted rounded-lg text-center">
        <p className="text-foreground">Este vídeo não pode ser incorporado</p>
        <a href={youtubeUrl} target="_blank" rel="noopener noreferrer" className="mt-3 px-5 py-2.5 rounded-full bg-red-600 text-white no-underline font-[Dancing_Script] transition-all hover:bg-red-700 hover:-translate-y-0.5">
          Assistir no YouTube
        </a>
      </div>
    );
  }

  return <div ref={containerRef} className="relative pb-[56.25%] h-0 overflow-hidden rounded-lg" />;
}; 