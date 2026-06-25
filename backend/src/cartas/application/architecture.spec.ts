import { readFileSync } from 'node:fs';
import { join } from 'node:path';

describe('Cartas application architecture', () => {
  it('does not depend on transport or infrastructure layers', () => {
    const files = [
      'services/cartas.service.ts',
      'factories/carta.factory.ts',
      'models/carta.models.ts',
      'ports/cartas.repository.port.ts',
      'ports/carta-notifier.port.ts',
    ];

    for (const file of files) {
      const source = readFileSync(join(__dirname, file), 'utf8');
      expect(source).not.toMatch(
        /(?:from|import\()\s*['"][^'"]*infrastructure/,
      );
      expect(source).not.toMatch(/(?:from|import\()\s*['"][^'"]*interfaces/);
    }
  });
});
