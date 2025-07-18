import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { FontAwesome } from '@expo/vector-icons';
import { useAuth } from '../hooks/useAuth';
import Button from '../components/Button';
import Input from '../components/Input';
import Toast from '../components/Toast';

function LoginScreen() {
  const router = useRouter();
  const { signIn, signUp, loading, error, clearError, resetPassword } = useAuth();
  
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');

  const showToastMessage = (message: string, type: 'success' | 'error') => {
    setToastMessage(message);
    setToastType(type);
    setShowToast(true);
  };

  const handleSubmit = async () => {
    if (!email || !password || (!isLogin && !displayName)) {
      showToastMessage('Por favor, preencha todos os campos', 'error');
      return;
    }

    try {
      if (isLogin) {
        const result = await signIn(email, password);
        if (result.success) {
          showToastMessage('Login realizado com sucesso!', 'success');
          setTimeout(() => {
            router.replace('/');
          }, 1500);
        } else {
          showToastMessage(result.error, 'error');
        }
      } else {
        const result = await signUp(email, password, displayName);
        if (result.success) {
          showToastMessage('Conta criada com sucesso!', 'success');
          setTimeout(() => {
            router.replace('/');
          }, 1500);
        } else {
          showToastMessage(result.error, 'error');
        }
      }
    } catch (error: any) {
      showToastMessage(error.message, 'error');
    }
  };

  const handleForgotPassword = async () => {
    if (!email) {
      showToastMessage('Digite seu email primeiro', 'error');
      return;
    }
    
    try {
      const result = await resetPassword(email);
      if (result.success) {
        showToastMessage('Email de reset enviado! Verifique sua caixa de entrada.', 'success');
      } else {
        showToastMessage(result.error, 'error');
      }
    } catch (error: any) {
      showToastMessage(error.message, 'error');
    }
  };

  return (
    <KeyboardAvoidingView 
      style={styles.container} 
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <View style={styles.header}>
          <Text style={styles.title}>💕 Amor & Login</Text>
          <Text style={styles.subtitle}>
            {isLogin ? 'Entre na sua conta de amor' : 'Crie sua conta de amor'}
          </Text>
        </View>

        <View style={styles.form}>
          {!isLogin && (
            <Input
              label="Nome"
              placeholder="Digite seu nome"
              value={displayName}
              onChangeText={setDisplayName}
              autoCapitalize="words"
            />
          )}

          <Input
            label="Email"
            placeholder="Digite seu email"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
          />

          <Input
            label="Senha"
            placeholder="Digite sua senha"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />

          <Button
            title={loading ? 'Carregando...' : (isLogin ? 'Entrar' : 'Cadastre-se')}
            onPress={handleSubmit}
            loading={loading}
            disabled={loading}
            variant="primary"
            size="large"
          />

          {isLogin && (
            <Button
              title="Esqueceu a senha?"
              onPress={handleForgotPassword}
              variant="outline"
              size="medium"
            />
          )}

          <View style={styles.switchContainer}>
            <Text style={styles.switchText}>
              {isLogin ? 'Não tem uma conta?' : 'Já tem uma conta?'}
            </Text>
            <Button
              title={isLogin ? 'Cadastre-se' : 'Entrar'}
              onPress={() => setIsLogin(!isLogin)}
              variant="outline"
              size="small"
            />
          </View>
        </View>
      </ScrollView>

      <Toast
        type={toastType}
        message={toastMessage}
        visible={showToast}
        onClose={() => setShowToast(false)}
      />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff8fa',
  },
  scrollContainer: {
    flexGrow: 1,
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginTop: 60,
    marginBottom: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#ff69b4',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  form: {
    flex: 1,
  },
  switchContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 20,
    gap: 10,
  },
  switchText: {
    color: '#666',
    fontSize: 14,
  },
});

export default LoginScreen; 