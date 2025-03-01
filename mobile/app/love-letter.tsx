import React from 'react';
import { ScrollView, View, Text, StyleSheet, Image } from 'react-native';

export default function LoveLetterScreen() {
  return (
    <ScrollView style={styles.container}>
      <View style={styles.letterContainer}>
        <Text style={styles.date}>23 de Novembro de 2023</Text>
        
        <Text style={styles.salutation}>Meu amor,</Text>
        
        <Text style={styles.paragraph}>
          Hoje, enquanto escrevo esta carta, meu coração transborda de amor e gratidão 
          por ter você em minha vida. Cada momento ao seu lado é um presente precioso 
          que guardo com carinho em minhas memórias.
        </Text>
        
        <Text style={styles.paragraph}>
          Lembro-me do nosso primeiro encontro como se fosse ontem. A maneira como 
          seus olhos brilhavam, seu sorriso tímido, e aquela conexão instantânea que 
          sentimos. Desde então, cada dia tem sido uma nova descoberta, uma nova 
          aventura ao seu lado.
        </Text>
        
        <Text style={styles.paragraph}>
          Você me faz querer ser uma pessoa melhor a cada dia. Seu amor me inspira, 
          me fortalece e me faz acreditar que tudo é possível quando estamos juntos. 
          Agradeço a Deus por ter colocado você em meu caminho.
        </Text>
        
        <Text style={styles.paragraph}>
          Prometo estar sempre ao seu lado, nos momentos de alegria e nos desafios. 
          Prometo te amar mais a cada dia, cuidar de você e construir uma vida 
          repleta de momentos especiais ao seu lado.
        </Text>
        
        <Text style={styles.closing}>
          Com todo meu amor,
        </Text>
        
        <Text style={styles.signature}>
          Seu amor ❤️
        </Text>

        <View style={styles.decorationContainer}>
          <View style={styles.heartDecoration} />
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
    padding: 20,
  },
  letterContainer: {
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 25,
    elevation: 3,
  },
  date: {
    color: '#666',
    fontSize: 14,
    marginBottom: 20,
    textAlign: 'right',
  },
  salutation: {
    fontSize: 24,
    color: '#ff69b4',
    marginBottom: 20,
    fontStyle: 'italic',
  },
  paragraph: {
    fontSize: 16,
    color: '#444',
    lineHeight: 24,
    marginBottom: 20,
    textAlign: 'justify',
  },
  closing: {
    fontSize: 18,
    color: '#ff69b4',
    marginTop: 30,
    marginBottom: 10,
    fontStyle: 'italic',
  },
  signature: {
    fontSize: 20,
    color: '#ff69b4',
    textAlign: 'right',
    fontWeight: 'bold',
  },
  decorationContainer: {
    alignItems: 'center',
    marginTop: 30,
  },
  heartDecoration: {
    width: 30,
    height: 30,
    backgroundColor: '#ff69b4',
    transform: [{ rotate: '45deg' }],
    position: 'relative',
    borderRadius: 5,
    
    // Criando o coração com pseudo-elementos usando sombras
    shadowColor: '#ff69b4',
    shadowOffset: { width: -15, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 15,
    elevation: 0,
  },
}); 