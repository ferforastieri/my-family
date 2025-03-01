import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';

export default function GamesScreen() {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [score, setScore] = useState(0);
  const [showResult, setShowResult] = useState(false);

  const questions = [
    {
      id: '1',
      question: 'Qual foi o local do nosso primeiro encontro?',
      options: [
        'Shopping',
        'Restaurante',
        'Parque',
        'Cinema'
      ],
      correct: 0
    },
    {
      id: '2',
      question: 'Qual é a minha comida favorita?',
      options: [
        'Pizza',
        'Hambúrguer',
        'Sushi',
        'Lasanha'
      ],
      correct: 2
    },
    // Adicione mais perguntas aqui
  ];

  const handleAnswer = (selectedOption: number) => {
    if (selectedOption === questions[currentQuestion].correct) {
      setScore(score + 1);
    }

    if (currentQuestion + 1 < questions.length) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      setShowResult(true);
    }
  };

  const resetQuiz = () => {
    setCurrentQuestion(0);
    setScore(0);
    setShowResult(false);
  };

  if (showResult) {
    return (
      <View style={styles.container}>
        <View style={styles.resultCard}>
          <Text style={styles.resultTitle}>Resultado</Text>
          <Text style={styles.resultScore}>
            Você acertou {score} de {questions.length} perguntas!
          </Text>
          <Text style={styles.resultMessage}>
            {score === questions.length 
              ? 'Parabéns! Você me conhece muito bem! ❤️'
              : 'Continue tentando! Ainda há mais para aprender sobre mim! 💕'}
          </Text>
          <TouchableOpacity style={styles.button} onPress={resetQuiz}>
            <Text style={styles.buttonText}>Jogar Novamente</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.pageTitle}>Quiz do Amor ❤️</Text>
      
      <View style={styles.questionCard}>
        <Text style={styles.questionNumber}>
          Pergunta {currentQuestion + 1} de {questions.length}
        </Text>
        <Text style={styles.question}>{questions[currentQuestion].question}</Text>
        
        <View style={styles.optionsContainer}>
          {questions[currentQuestion].options.map((option, index) => (
            <TouchableOpacity
              key={`${questions[currentQuestion].id}-${index}`}
              style={styles.optionButton}
              onPress={() => handleAnswer(index)}
            >
              <Text style={styles.optionText}>{option}</Text>
            </TouchableOpacity>
          ))}
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
  pageTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#ff69b4',
    textAlign: 'center',
    marginBottom: 30,
  },
  questionCard: {
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 20,
    elevation: 3,
  },
  questionNumber: {
    color: '#666',
    fontSize: 16,
    marginBottom: 10,
  },
  question: {
    fontSize: 20,
    color: '#ff69b4',
    fontWeight: 'bold',
    marginBottom: 20,
  },
  optionsContainer: {
    gap: 10,
  },
  optionButton: {
    backgroundColor: '#fff8fa',
    borderRadius: 10,
    padding: 15,
    borderWidth: 1,
    borderColor: '#ff69b4',
  },
  optionText: {
    color: '#ff69b4',
    fontSize: 16,
    textAlign: 'center',
  },
  resultCard: {
    backgroundColor: 'white',
    borderRadius: 15,
    padding: 20,
    alignItems: 'center',
    elevation: 3,
  },
  resultTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#ff69b4',
    marginBottom: 20,
  },
  resultScore: {
    fontSize: 20,
    color: '#666',
    marginBottom: 10,
  },
  resultMessage: {
    fontSize: 18,
    color: '#ff69b4',
    textAlign: 'center',
    marginBottom: 30,
  },
  button: {
    backgroundColor: '#ff69b4',
    paddingHorizontal: 30,
    paddingVertical: 15,
    borderRadius: 25,
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
}); 