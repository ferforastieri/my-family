import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

// Configurar como as notificações são exibidas quando o app está em foreground
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

class NotificationService {
  // Solicitar permissão para notificações
  async requestPermission(): Promise<boolean> {
    try {
      if (Device.isDevice) {
        const { status: existingStatus } = await Notifications.getPermissionsAsync();
        let finalStatus = existingStatus;
        
        if (existingStatus !== 'granted') {
          const { status } = await Notifications.requestPermissionsAsync();
          finalStatus = status;
        }
        
        if (finalStatus !== 'granted') {
          console.log('Permissão de notificação negada');
          return false;
        }
        
        console.log('Permissão de notificação concedida');
        return true;
      } else {
        console.log('Dispositivo físico necessário para notificações');
        return false;
      }
    } catch (error) {
      console.error('Erro ao solicitar permissão:', error);
      return false;
    }
  }

  // Obter token Expo Push
  async getExpoPushToken(): Promise<string | null> {
    try {
      if (!Device.isDevice) {
        console.log('Dispositivo físico necessário para push notifications');
        return null;
      }

      const token = await Notifications.getExpoPushTokenAsync({
        projectId: '7c530d57-fade-41f3-842c-a905d03557f8', // Seu projectId do EAS
      });
      
      console.log('Expo Push Token:', token.data);
      return token.data;
    } catch (error) {
      console.error('Erro ao obter Expo Push token:', error);
      return null;
    }
  }

  // Configurar listeners para notificações
  setupNotificationListeners() {
    // Notificação recebida quando app está em foreground
    const foregroundSubscription = Notifications.addNotificationReceivedListener(notification => {
      console.log('Notificação recebida em foreground:', notification);
    });

    // Notificação tocada/aberta pelo usuário
    const responseSubscription = Notifications.addNotificationResponseReceivedListener(response => {
      console.log('Notificação tocada:', response);
      this.handleNotificationResponse(response);
    });

    return () => {
      foregroundSubscription?.remove();
      responseSubscription?.remove();
    };
  }

  // Lidar com resposta da notificação (quando usuário toca)
  private handleNotificationResponse(response: Notifications.NotificationResponse) {
    const { title, body, data } = response.notification.request.content;
    console.log('Notificação tocada:', { title, body, data });
    
    // Aqui você pode navegar para uma tela específica baseada na notificação
    if (data?.type === 'message') {
      console.log('Navegando para mensagens');
      // Implementar navegação
    }
  }

  // Agendar notificação local
  async scheduleLocalNotification(
    title: string,
    body: string,
    trigger?: any,
    data?: any
  ) {
    try {
      const identifier = await Notifications.scheduleNotificationAsync({
        content: {
          title,
          body,
          data: data || {},
          sound: 'default',
        },
        trigger: trigger || null, // null = enviar imediatamente
      });
      
      console.log('Notificação local agendada:', identifier);
      return identifier;
    } catch (error) {
      console.error('Erro ao agendar notificação local:', error);
      return null;
    }
  }

  // Configurar notificações carinhosas automáticas
  async setupLoveNotifications() {
    try {
      // Cancelar notificações existentes
      await this.cancelAllNotifications();

      // 1. Bom dia - 8h da manhã
      await this.scheduleLocalNotification(
        '🌅 Bom dia, amor!',
        'Que seu dia seja cheio de amor e alegria! 💕',
        {
          hour: 8,
          minute: 0,
          repeats: true,
        },
        { type: 'morning' }
      );

      // 2. Boa tarde - 12h
      await this.scheduleLocalNotification(
        '☀️ Boa tarde!',
        'Espero que seu dia esteja sendo maravilhoso! 😊',
        {
          hour: 12,
          minute: 0,
          repeats: true,
        },
        { type: 'afternoon' }
      );

      // 3. Boa noite - 20h
      await this.scheduleLocalNotification(
        '🌙 Boa noite!',
        'Durma com pensamentos de amor! Sonhe comigo! 💫',
        {
          hour: 20,
          minute: 0,
          repeats: true,
        },
        { type: 'evening' }
      );

            // 4. Boa noite - 20h
            await this.scheduleLocalNotification(
                '🌙 Me da o cuzinho!',
                'Quero comer seu rabo! 💫',
                {
                  hour: 23,
                  minute: 0,
                  repeats: true,
                },
                { type: 'evening' }
              );



      // 4. Mensagem de amor - 15h
      await this.scheduleLocalNotification(
        '💕 Pensando em você!',
        'Você é a pessoa mais especial da minha vida! ❤️',
        {
          hour: 15,
          minute: 0,
          repeats: true,
        },
        { type: 'love' }
      );

      // 5. Lembrete de beijo - 18h
      await this.scheduleLocalNotification(
        '💋 Hora do beijo!',
        'Não esqueça de dar um beijo hoje! 😘',
        {
          hour: 18,
          minute: 0,
          repeats: true,
        },
        { type: 'kiss' }
      );

      console.log('Notificações carinhosas configuradas com sucesso!');
      return true;
    } catch (error) {
      console.error('Erro ao configurar notificações carinhosas:', error);
      return false;
    }
  }

  // Cancelar notificação local
  async cancelNotification(identifier: string) {
    try {
      await Notifications.cancelScheduledNotificationAsync(identifier);
      console.log('Notificação cancelada:', identifier);
    } catch (error) {
      console.error('Erro ao cancelar notificação:', error);
    }
  }

  // Cancelar todas as notificações locais
  async cancelAllNotifications() {
    try {
      await Notifications.cancelAllScheduledNotificationsAsync();
      console.log('Todas as notificações canceladas');
    } catch (error) {
      console.error('Erro ao cancelar todas as notificações:', error);
    }
  }

  // Enviar notificação para um usuário específico (via Expo Push)
  async sendNotificationToUser(
    expoPushToken: string,
    title: string,
    body: string,
    data?: any
  ) {
    try {
      const message = {
        to: expoPushToken,
        sound: 'default',
        title,
        body,
        data: data || {},
      };

      // Enviar via Expo Push API
      const response = await fetch('https://exp.host/--/api/v2/push/send', {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Accept-encoding': 'gzip, deflate',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      });

      const result = await response.json();
      console.log('Notificação enviada:', result);
      return result;
    } catch (error) {
      console.error('Erro ao enviar notificação:', error);
      return null;
    }
  }
}

export default new NotificationService(); 