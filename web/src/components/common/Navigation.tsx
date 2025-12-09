import { useLocation, useNavigate } from 'react-router-dom';
import { Navigation as UINavigation } from '../ui/layout';
import type { NavigationItem } from '../ui/layout/navigation';
import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { 
  HomeIcon, 
  BookOpenIcon, 
  HeartIcon, 
  MusicalNoteIcon, 
  PhotoIcon, 
  EnvelopeIcon, 
  GiftIcon, 
  SparklesIcon,
  ArrowRightOnRectangleIcon
} from '@heroicons/react/24/outline';

const Navigation = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { signOut, user } = useAuth();

  const handleLogout = async () => {
    await signOut();
    navigate('/login');
  };

  const navItems: NavigationItem[] = [
    {
      name: 'Nosso Início',
      href: '/',
      icon: HomeIcon,
    },
    {
      name: 'Nossa Jornada',
      href: '/nossa-historia',
      icon: BookOpenIcon,
    },
    {
      name: 'Quiz do Amor',
      href: '/quiz-do-amor',
      icon: HeartIcon,
    },
    {
      name: 'Nossa Playlist',
      href: '/playlist',
      icon: MusicalNoteIcon,
    },
    {
      name: 'Memórias em Fotos',
      href: '/galeria',
      icon: PhotoIcon,
    },
    {
      name: 'Palavras do Coração',
      href: '/mensagens',
      icon: EnvelopeIcon,
    },
    {
      name: 'Carta de Amor',
      href: '/carta-de-amor',
      icon: GiftIcon,
    },
    {
      name: 'Flor para Minha Esposa',
      href: '/flor-para-esposa',
      icon: SparklesIcon,
    },
  ];

  const LinkComponent = ({ to, className, children, onClick }: { to: string; className?: string; children: React.ReactNode; onClick?: () => void }) => (
    <Link to={to} className={className} onClick={onClick}>
      {children}
    </Link>
  );

  return (
    <UINavigation
      items={navItems}
      currentPath={location.pathname}
      LinkComponent={LinkComponent}
      className="bg-pink-200"
      logo={
        <span className="text-xl font-bold text-love-primary">
          💕 Nossa Família
        </span>
      }
      rightContent={
        user && (
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-love-primary-dark hover:bg-pink-300/50 transition-colors"
          >
            <ArrowRightOnRectangleIcon className="h-5 w-5" />
            <span className="hidden md:inline">Sair</span>
          </button>
        )
      }
    />
  );
};

export default Navigation;

