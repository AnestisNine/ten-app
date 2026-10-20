/** Browser-side helpers for the public API (shows, products, forms). */
export const apiUrl = () =>
  document.querySelector<HTMLMetaElement>('meta[name="tbn-api"]')?.content ?? '';

export async function getJson<T>(path: string): Promise<T> {
  const res = await fetch(`${apiUrl()}${path}`, { headers: { accept: 'application/json' } });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return (await res.json()) as T;
}

export async function postJson(path: string, body: unknown): Promise<Response> {
  return fetch(`${apiUrl()}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

export const escapeHtml = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);

export function formatPrice(cents: number, lang: string) {
  return new Intl.NumberFormat('en-IE', { style: 'currency', currency: 'EUR' }).format(cents / 100);
}
