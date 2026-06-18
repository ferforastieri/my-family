import { BadRequestException, Injectable } from '@nestjs/common';
import {
  HomeEventWrite,
  HomeSettingsRepository,
} from '../infrastructure/home-settings.repository';

const defaultEvents: HomeEventWrite[] = [
  {
    title: 'Começamos a Namorar',
    icon: '💕',
    date: new Date('2024-10-12T12:00:00.000Z'),
    message: 'Desde o primeiro olhar, sabia que você era especial',
    countDirection: 'forward',
  },
  {
    title: 'Nosso Casamento',
    icon: '💍',
    date: new Date('2025-04-15T12:00:00.000Z'),
    message: 'O dia mais feliz da minha vida ao seu lado',
    countDirection: 'forward',
  },
  {
    title: 'Nascimento do Fernando',
    icon: '👶',
    date: new Date('2026-06-15T12:00:00.000Z'),
    message: 'Nosso maior presente de amor chegando',
    countDirection: 'backward',
  },
];

@Injectable()
export class HomeSettingsService {
  constructor(private repository: HomeSettingsRepository) {}

  async get() {
    const current = await this.repository.find();
    if (current?.events?.length) {
      return this.toDto(current.events, current.galleryImages ?? []);
    }
    const created = await this.repository.save({
      events: defaultEvents,
      galleryImages: [],
    });
    return this.toDto(created?.events ?? defaultEvents);
  }

  async update(input: {
    events?: Array<{
      title?: string;
      icon?: string;
      date?: string;
      message?: string;
      countDirection?: string;
      hidden?: boolean;
    }>;
    galleryImages?: string[];
  }) {
    if (!Array.isArray(input?.events) || input.events.length < 1) {
      throw new BadRequestException('Informe pelo menos um card da Home.');
    }
    const events = input.events.map((event, index) => {
      const title = event.title?.trim();
      const icon = event.icon?.trim();
      const message = event.message?.trim();
      const date = new Date(event.date ?? '');
      const countDirection: HomeEventWrite['countDirection'] =
        event.countDirection === 'backward' ? 'backward' : 'forward';
      if (!title || !icon || !message || Number.isNaN(date.getTime())) {
        throw new BadRequestException(
          `Preencha corretamente o evento ${index + 1}.`,
        );
      }
      return {
        title,
        icon,
        message,
        date,
        countDirection,
        hidden: event.hidden === true,
      };
    });
    const galleryImages = Array.isArray(input.galleryImages)
      ? input.galleryImages
          .map((image) => image?.trim())
          .filter((image): image is string => !!image)
      : [];
    const saved = await this.repository.save({ events, galleryImages });
    return this.toDto(
      saved?.events ?? events,
      saved?.galleryImages ?? galleryImages,
    );
  }

  private toDto(events: HomeEventWrite[], galleryImages: string[] = []) {
    return {
      events: events.map((event) => ({
        title: event.title,
        icon: event.icon,
        date: new Date(event.date).toISOString(),
        message: event.message,
        hidden: event.hidden === true,
        countDirection:
          event.countDirection === 'backward' ? 'backward' : 'forward',
      })),
      galleryImages,
    };
  }
}
