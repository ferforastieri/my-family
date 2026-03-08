import React from 'react';

interface SpotifyPlayerProps {
  spotifyUrl: string;
}

export const SpotifyPlayer: React.FC<SpotifyPlayerProps> = ({ spotifyUrl }) => {
  const getSpotifyEmbedUrl = (url: string) => {
    const trackId = url.split('/track/')[1]?.split('?')[0];
    return trackId ? `https://open.spotify.com/embed/track/${trackId}` : '';
  };

  const embedUrl = getSpotifyEmbedUrl(spotifyUrl);

  return (
    <div className="relative pb-[152px] h-0 overflow-hidden">
      <iframe src={embedUrl} allow="encrypted-media" allowFullScreen className="absolute top-0 left-0 w-full h-full border-0 rounded-lg" />
    </div>
  );
}; 