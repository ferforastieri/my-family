export function parseListMessage(text: string) {
  const trimmed = text.trim();
  const match = /^lista(?:\s*:\s*|\s+)([\s\S]*)$/i.exec(trimmed);
  if (!match) return null;

  const lines = match[1]
    .trim()
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const first = lines.shift() ?? '';
  const inline = first.includes(':') ? first.split(':') : null;
  const title = (inline ? inline.shift() : first)?.trim() || 'Lista';
  const firstItems = inline?.join(':') ?? '';
  const items = [firstItems, ...lines]
    .flatMap((line) => line.split(/[,;]/))
    .map((item) => item.replace(/^[-*•]\s*/, '').trim())
    .filter(Boolean);

  return { title, items: items.length ? items : ['Novo item'] };
}
