import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image } from 'react-native';

export default function PlaylistScreen() {
  const [currentSong, setCurrentSong] = useState<string | null>(null);

  const songs = [
    {
      id: '1',
      title: 'Perfect',
      artist: 'Ed Sheeran',
      description: 'Nossa música do primeiro beijo...',
      emoji: '💑'
    },
    {
      id: '2',
      title: 'All of Me',
      artist: 'John Legend',
      description: 'A música que define nosso amor...',
      emoji: '❤️'
    },
    {
      id: '3',
      title: 'Thinking Out Loud',
      artist: 'Ed Sheeran',
      description: 'Para dançar juntinhos...',
      emoji: '💃'
    },
    {
      id: '4',
      title: 'Just the Way You Are',
      artist: 'Bruno Mars',
      description: 'Porque você é perfeita do jeito que é...',
      emoji: '✨'
    },
    {
      id: '5',
      title: 'Can\'t Help Falling in Love',
      artist: 'Elvis Presley',
      description: 'Um clássico que nunca sai de moda...',
      emoji: '🎵'
    },
  ];

  const toggleSong = (songId: string) => {
    setCurrentSong(currentSong === songId ? null : songId);
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.pageTitle}>Nossa Playlist ❤️</Text>
      
      <Text style={styles.subtitle}>
        As músicas que marcaram nossa história de amor...
      </Text>

      <View style={styles.songsContainer}>
        {songs.map((song) => (
          <TouchableOpacity
            key={song.id}
            style={[
              styles.songCard,
              currentSong === song.id && styles.songCardActive
            ]}
            onPress={() => toggleSong(song.id)}
          >
            <View style={styles.songHeader}>
              <View>
                <Text style={styles.songTitle}>{song.title}</Text>
                <Text style={styles.songArtist}>{song.artist}</Text>
              </View>
              <Text style={styles.songEmoji}>{song.emoji}</Text>
            </View>
            
            {currentSong === song.id && (
              <View style={styles.songDetails}>
                <Text style={styles.songDescription}>{song.description}</Text>
                <View style={styles.playButton}>
                  <Text style={styles.playButtonText}>▶️ Ouvir no Spotify</Text>
                </View>
              </View>
            )}
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.footer}>
        Toque nas músicas para ver mais detalhes e ouvir no Spotify 🎵
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
    padding: 20,
  },
  pageTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#ff69b4',
    textAlign: 'center',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 30,
    fontStyle: 'italic',
  },
  songsContainer: {
    gap: 15,
  },
  songCard: {
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 15,
    elevation: 2,
  },
  songCardActive: {
    backgroundColor: '#fff0f5',
    borderColor: '#ff69b4',
    borderWidth: 1,
  },
  songHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  songTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#ff69b4',
    marginBottom: 5,
  },
  songArtist: {
    fontSize: 14,
    color: '#666',
  },
  songEmoji: {
    fontSize: 24,
  },
  songDetails: {
    marginTop: 15,
    paddingTop: 15,
    borderTopWidth: 1,
    borderTopColor: '#ffcce5',
  },
  songDescription: {
    fontSize: 14,
    color: '#666',
    fontStyle: 'italic',
    marginBottom: 15,
  },
  playButton: {
    backgroundColor: '#1DB954', // Cor do Spotify
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 20,
    alignSelf: 'center',
  },
  playButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
  footer: {
    marginTop: 30,
    textAlign: 'center',
    color: '#666',
    fontSize: 14,
    fontStyle: 'italic',
  },
}); 