import auth, { FirebaseAuthTypes } from '@react-native-firebase/auth';

export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

export interface AuthState {
  user: User | null;
  loading: boolean;
  error: string | null;
}

class AuthService {
  // Login com email e senha
  async signInWithEmail(email: string, password: string): Promise<User> {
    try {
      const userCredential = await auth().signInWithEmailAndPassword(email, password);
      return this.formatUser(userCredential.user);
    } catch (error: any) {
      throw new Error(this.getErrorMessage(error.code));
    }
  }

  // Registro com email e senha
  async signUpWithEmail(email: string, password: string, displayName: string): Promise<User> {
    try {
      const userCredential = await auth().createUserWithEmailAndPassword(email, password);
      
      // Atualizar display name
      await userCredential.user.updateProfile({
        displayName: displayName
      });

      return this.formatUser(userCredential.user);
    } catch (error: any) {
      throw new Error(this.getErrorMessage(error.code));
    }
  }

  // Logout
  async signOut(): Promise<void> {
    try {
      await auth().signOut();
    } catch (error: any) {
      throw new Error('Erro ao fazer logout');
    }
  }

  // Reset de senha
  async resetPassword(email: string): Promise<void> {
    try {
      await auth().sendPasswordResetEmail(email);
    } catch (error: any) {
      throw new Error(this.getErrorMessage(error.code));
    }
  }

  // Obter usuário atual
  getCurrentUser(): User | null {
    const user = auth().currentUser;
    return user ? this.formatUser(user) : null;
  }

  // Listener para mudanças de autenticação
  onAuthStateChanged(callback: (user: User | null) => void): () => void {
    return auth().onAuthStateChanged((user) => {
      callback(user ? this.formatUser(user) : null);
    });
  }

  // Formatar usuário para interface consistente
  private formatUser(firebaseUser: FirebaseAuthTypes.User): User {
    return {
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
    };
  }

  // Traduzir códigos de erro do Firebase
  private getErrorMessage(errorCode: string): string {
    const errorMessages: { [key: string]: string } = {
      'auth/user-not-found': 'Usuário não encontrado',
      'auth/wrong-password': 'Senha incorreta',
      'auth/invalid-email': 'Email inválido',
      'auth/weak-password': 'Senha muito fraca',
      'auth/email-already-in-use': 'Email já está em uso',
      'auth/too-many-requests': 'Muitas tentativas. Tente novamente mais tarde',
      'auth/network-request-failed': 'Erro de conexão. Verifique sua internet',
      'auth/user-disabled': 'Conta desabilitada',
      'auth/operation-not-allowed': 'Operação não permitida',
    };

    return errorMessages[errorCode] || 'Erro desconhecido';
  }
}

export default new AuthService(); 