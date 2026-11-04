import {
  Bath,
  BookOpen,
  Briefcase,
  Coffee,
  DoorOpen,
  FlaskConical,
  MapPin,
  Mic,
  Presentation,
  SquareParking,
  Trophy,
  type LucideIcon,
} from 'lucide-react';
import type { Categoria } from '@/lib/tipos';

export const ICONO_CATEGORIA: Record<Categoria, LucideIcon> = {
  aula: Presentation,
  laboratorio: FlaskConical,
  oficina: Briefcase,
  auditorio: Mic,
  biblioteca: BookOpen,
  bano: Bath,
  cafeteria: Coffee,
  deportivo: Trophy,
  porteria: DoorOpen,
  parqueadero: SquareParking,
  otro: MapPin,
};
