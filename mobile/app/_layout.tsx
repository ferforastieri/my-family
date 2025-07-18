import { Drawer } from 'expo-router/drawer';
import { TouchableOpacity } from 'react-native';
import { FontAwesome } from '@expo/vector-icons';
import { useCallback, useState, useEffect } from 'react';
import { DrawerActions, useNavigation } from '@react-navigation/native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { StatusBar } from 'expo-status-bar';
import AnimatedSplashScreen from '../components/AnimatedSplashScreen';
import * as SplashScreen from 'expo-splash-screen';
import notificationService from '../api/notifications/notificationService';
import { useAuth } from '../hooks/useAuth';

// Esconde a splash screen nativa imediatamente
SplashScreen.hideAsync();

export default function Layout() {
  const navigation = useNavigation();
  const [isReady, setIsReady] = useState(false);
  const { isAuthenticated } = useAuth();

  const openMenu = useCallback(() => {
    navigation.dispatch(DrawerActions.toggleDrawer());
  }, [navigation]);

  // Configurar notificações
  useEffect(() => {
    const setupNotifications = async () => {
      try {
        // Solicitar permissão
        const hasPermission = await notificationService.requestPermission();
        
        if (hasPermission) {
          // Obter token Expo Push
          const token = await notificationService.getExpoPushToken();
          
          // Configurar listeners
          const unsubscribe = notificationService.setupNotificationListeners();
          
          // Configurar notificações carinhosas automáticas
          await notificationService.setupLoveNotifications();
          
          // Salvar token no backend (opcional)
          if (token) {
            console.log('Expo Push Token salvo:', token);
            // Aqui você pode salvar o token no seu backend
          }
          
          return unsubscribe;
        }
      } catch (error) {
        console.error('Erro ao configurar notificações:', error);
      }
    };

    const unsubscribe = setupNotifications();
    
    return () => {
      // Cleanup se necessário
      if (unsubscribe) {
        unsubscribe.then(unsub => unsub?.());
      }
    };
  }, []);

  // Se a splash screen não estiver pronta, mostre-a
  if (!isReady) {
    return <AnimatedSplashScreen onFinish={() => setIsReady(true)} />;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Drawer
        screenOptions={{
          headerStyle: {
            backgroundColor: '#ff69b4',
          },
          headerTintColor: 'white',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
          headerRight: () => (
            <TouchableOpacity 
              onPress={openMenu}
              style={{ marginRight: 15 }}
            >
              <FontAwesome name="bars" size={24} color="white" />
            </TouchableOpacity>
          ),
          drawerPosition: 'right',
          drawerStyle: {
            backgroundColor: '#fff8fa',
            width: 280,
          },
          drawerActiveBackgroundColor: '#ff69b4',
          drawerActiveTintColor: 'white',
          drawerInactiveTintColor: '#666',
          headerLeft: () => null,
          swipeEnabled: true,
          swipeEdgeWidth: 100,
        }}
      >
        <Drawer.Screen
          name="index"
          options={{
            title: 'Início',
            headerTitle: 'Familia & Pessoa 💑',
            drawerIcon: ({ color }) => <FontAwesome name="home" size={24} color={color} />,
          }}
        />
        <Drawer.Screen
          name="history"
          options={{
            title: 'Nossa História',
            drawerIcon: ({ color }) => <FontAwesome name="book" size={24} color={color} />,
          }}
        />
        <Drawer.Screen
          name="games"
          options={{
            title: 'Quiz do Amor',
            drawerIcon: ({ color }) => <FontAwesome name="gamepad" size={24} color={color} />,
          }}
        />
        <Drawer.Screen
          name="messages"
          options={{
            title: 'Mensagens',
            drawerIcon: ({ color }) => <FontAwesome name="heart" size={24} color={color} />,
          }}
        />
        <Drawer.Screen
          name="love-letter"
          options={{
            title: 'Carta de Amor',
            drawerIcon: ({ color }) => <FontAwesome name="envelope" size={24} color={color} />,
          }}
        />
        <Drawer.Screen
          name="flower"
          options={{
            title: 'Flor Virtual',
            drawerIcon: ({ color }) => <FontAwesome name="star" size={24} color={color} />,
          }}
        />
        <Drawer.Screen
          name="playlist"
          options={{
            title: 'Nossa Playlist',
            drawerIcon: ({ color }) => <FontAwesome name="music" size={24} color={color} />,
          }}
        />
        {isAuthenticated && (
          <Drawer.Screen
            name="gallery"
            options={{
              title: '📸 Nossa Galeria',
              drawerIcon: ({ color }) => <FontAwesome name="image" size={24} color={color} />,
            }}
          />
        )}
        <Drawer.Screen
          name="login"
          options={{
            title: 'Login',
            drawerIcon: ({ color }) => <FontAwesome name="lock" size={24} color={color} />,
          }}
        />
      </Drawer>
      <StatusBar style="light" />
    </GestureHandlerRootView>
  );
}
