import styled from 'styled-components';

const PlayerContainer = styled.div`
  margin-top: 1rem;
  width: 100%;
  
  iframe {
    border-radius: 12px;
    width: 100%;
    max-height: 80px;
    border: none;
  }
`;

interface SpotifyPlayerProps {
  spotifyUrl: string;
}

export const SpotifyPlayer = ({ spotifyUrl }: SpotifyPlayerProps) => {
  // Converte URL normal do Spotify para URL de embed
  const getEmbedUrl = (url: string) => {
    const trackId = url.split('/track/')[1]?.split('?')[0];
    return trackId 
      ? `https://open.spotify.com/embed/track/${trackId}` 
      : null;
  };

  const embedUrl = getEmbedUrl(spotifyUrl);
  
  if (!embedUrl) return null;

  return (
    <PlayerContainer>
      <iframe
        src={embedUrl}
        allow="encrypted-media"
        allowTransparency={true}
        loading="lazy"
      />
    </PlayerContainer>
  );
}; 