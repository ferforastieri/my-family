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
  },
  {
    title: 'Nosso Casamento',
    icon: '💍',
    date: new Date('2025-04-15T12:00:00.000Z'),
    message: 'O dia mais feliz da minha vida ao seu lado',
  },
  {
    title: 'Nascimento do Fernando',
    icon: '👶',
    date: new Date('2026-06-15T12:00:00.000Z'),
    message: 'Nosso maior presente de amor chegando',
  },
];

@Injectable()
export class HomeSettingsService {
  constructor(private repository: HomeSettingsRepository) {}

  async get() {
    const current = await this.repository.find();
    if (current?.events?.length) return this.toDto(current.events);
    const created = await this.repository.save(defaultEvents);
    return this.toDto(created?.events ?? defaultEvents);
  }

  async update(input: {
    events?: Array<{
      title?: string;
      icon?: string;
      date?: string;
      message?: string;
    }>;
  }) {
    if (!Array.isArray(input?.events) || input.events.length !== 3) {
      throw new BadRequestException('Informe exatamente três cards da Home.');
    }
    const events = input.events.map((event, index) => {
      const title = event.title?.trim();
      const icon = event.icon?.trim();
      const message = event.message?.trim();
      const date = new Date(event.date ?? '');
      if (!title || !icon || !message || Number.isNaN(date.getTime())) {
        throw new BadRequestException(
          `Preencha corretamente o evento ${index + 1}.`,
        );
      }
      return { title, icon, message, date };
    });
    const saved = await this.repository.save(events);
    return this.toDto(saved?.events ?? events);
  }

  private toDto(events: HomeEventWrite[]) {
    return {
      events: events.map((event) => ({
        title: event.title,
        icon: event.icon,
        date: new Date(event.date).toISOString(),
        message: event.message,
      })),
    };
  }
}
