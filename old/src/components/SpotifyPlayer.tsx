import React from 'react';
import styled from 'styled-components';

const PlayerContainer = styled.div`
  position: relative;
  padding-bottom: 152px;
  height: 0;
  overflow: hidden;
  
  iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
    border-radius: 8px;
  }
`;

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
    <PlayerContainer>
      <iframe
        src={embedUrl}
        allow="encrypted-media"
        allowFullScreen
      />
    </PlayerContainer>
  );
}; 