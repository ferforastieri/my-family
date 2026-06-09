import { parseListMessage } from './list-message.parser';

describe('parseListMessage', () => {
  it('accepts title after Lista and multiline items', () => {
    expect(parseListMessage('Lista Compras:\n\n- Arroz')).toEqual({
      title: 'Compras',
      items: ['Arroz'],
    });
  });

  it('accepts the Lista: title format', () => {
    expect(parseListMessage('Lista: Compras\n- Arroz\n- Feijão')).toEqual({
      title: 'Compras',
      items: ['Arroz', 'Feijão'],
    });
  });

  it('accepts inline items', () => {
    expect(parseListMessage('Lista Compras: Arroz, Feijão; Leite')).toEqual({
      title: 'Compras',
      items: ['Arroz', 'Feijão', 'Leite'],
    });
  });

  it('ignores regular chat messages', () => {
    expect(parseListMessage('Precisamos comprar arroz')).toBeNull();
  });
});
