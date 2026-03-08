import { useLocation, useNavigate, Link } from 'react-router-dom';
import { Navigation as UINavigation } from '../ui/layout';
import type { NavigationItem } from '../ui/layout/navigation';
import { useAuth } from '../../contexts/AuthContext';
import { DropdownMenu, DropdownMenuItem } from '../ui/feedback';
import ThemeDropdown from './ThemeDropdown';
import { BellIcon } from '@heroicons/react/24/outline';
import {
  HomeIcon,
  BookOpenIcon,
  HeartIcon,
  MusicalNoteIcon,
  PhotoIcon,
  EnvelopeIcon,
  GiftIcon,
  SparklesIcon,
  ArrowRightOnRectangleIcon,
  UserCircleIcon,
  UserIcon,
} from '@heroicons/react/24/outline';

const baseNavItems: NavigationItem[] = [
  { name: 'Nosso Início', href: '/', icon: HomeIcon },
  { name: 'Nossa Jornada', href: '/nossa-historia', icon: BookOpenIcon },
  { name: 'Quiz do Amor', href: '/quiz-do-amor', icon: HeartIcon },
  { name: 'Nossa Playlist', href: '/playlist', icon: MusicalNoteIcon },
  { name: 'Palavras do Coração', href: '/mensagens', icon: EnvelopeIcon },
  { name: 'Carta de Amor', href: '/carta-de-amor', icon: GiftIcon },
  { name: 'Flor para Minha Esposa', href: '/flor-para-esposa', icon: SparklesIcon },
];

const memoriaItem: NavigationItem = {
  name: 'Memórias em Fotos',
  href: '/galeria',
  icon: PhotoIcon,
};

const Navigation = ({ onOpenNotifications }: { onOpenNotifications: () => void }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const { signOut, user } = useAuth();

  const navItems = user ? [...baseNavItems, memoriaItem] : baseNavItems;

  const handleLogout = async () => {
    await signOut();
    navigate('/');
  };

  const LinkComponent = ({ to, className, children, onClick }: { to: string; className?: string; children: React.ReactNode; onClick?: () => void }) => (
    <Link to={to} className={className} onClick={onClick}>
      {children}
    </Link>
  );

  const rightContent = (
    <div className="flex items-center gap-2 sm:gap-3">
      <button
        type="button"
        onClick={onOpenNotifications}
        className="flex items-center justify-center w-9 h-9 rounded-full bg-muted hover:bg-accent text-foreground border border-border transition-colors"
        aria-label="Notificações"
      >
        <BellIcon className="h-5 w-5" />
      </button>
      <ThemeDropdown />
      {user ? (
        <DropdownMenu
          align="right"
          side="bottom"
          trigger={
            <button
              type="button"
              className="flex items-center justify-center w-9 h-9 rounded-full bg-primary text-primary-foreground hover:opacity-90 transition-opacity border border-border"
              aria-label="Menu do usuário"
            >
              <UserIcon className="h-5 w-5" />
            </button>
          }
        >
          <DropdownMenuItem asChild>
            <Link to="/perfil" className="flex items-center gap-2 px-2 py-1.5 rounded-sm hover:bg-accent">
              <UserIcon className="h-4 w-4" />
              Meu perfil
            </Link>
          </DropdownMenuItem>
          <DropdownMenuItem onClick={handleLogout} className="flex items-center gap-2 text-destructive hover:bg-accent">
            <ArrowRightOnRectangleIcon className="h-4 w-4" />
            Sair
          </DropdownMenuItem>
        </DropdownMenu>
      ) : (
        <Link
          to="/login"
          className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-primary hover:bg-accent transition-colors"
        >
          <UserCircleIcon className="h-5 w-5" />
          <span className="hidden md:inline">Entrar</span>
        </Link>
      )}
    </div>
  );

  return (
    <UINavigation
      items={navItems}
      currentPath={location.pathname}
      LinkComponent={LinkComponent}
      className="bg-card border-b border-border"
      logo={
        <span className="text-xl font-bold text-primary">
          💕 Nossa Família
        </span>
      }
      rightContent={rightContent}
    />
  );
};

export default Navigation;
