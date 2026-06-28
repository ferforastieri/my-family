import { Controller, Get } from '@nestjs/common';
import { ClientPanelService } from './client-panel.service';

@Controller('client')
export class ClientPanelController {
  constructor(private readonly panel: ClientPanelService) {}

  @Get('dashboard')
  dashboard() {
    return this.panel.dashboard();
  }
}
