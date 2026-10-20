/** Minimal iCalendar (RFC 5545) writer for read-only subscription feeds. */

export interface IcsEvent {
  uid: string;
  summary: string;
  description?: string;
  location?: string;
  /** All-day event on this date (YYYY-MM-DD). */
  date?: string;
  /** Timed event. */
  start?: Date;
  end?: Date;
  updatedAt: Date;
  status?: 'CONFIRMED' | 'TENTATIVE' | 'CANCELLED';
}

const escapeText = (v: string) => v.replace(/\\/g, '\\\\').replace(/;/g, '\;').replace(/,/g, '\\,').replace(/\r?\n/g, '\\n');

const utc = (d: Date) => d.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');

const ymd = (date: string) => date.replace(/-/g, '');

function nextDay(date: string) {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

/** Folds lines longer than 75 octets, as the spec requires. */
function fold(line: string): string {
  const bytes = Buffer.from(line, 'utf8');
  if (bytes.length <= 75) return line;
  const parts: string[] = [];
  let current = '';
  let size = 0;
  for (const ch of line) {
    const n = Buffer.byteLength(ch, 'utf8');
    if (size + n > (parts.length === 0 ? 75 : 74)) {
      parts.push(current);
      current = '';
      size = 0;
    }
    current += ch;
    size += n;
  }
  parts.push(current);
  return parts.join('\r\n ');
}

export function buildCalendar(name: string, events: IcsEvent[]): string {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//The Bonnie Nettles//TBN Manager//EL',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    `X-WR-CALNAME:${escapeText(name)}`,
    'X-WR-TIMEZONE:Europe/Athens',
    'REFRESH-INTERVAL;VALUE=DURATION:PT1H',
  ];
  for (const e of events) {
    lines.push('BEGIN:VEVENT', `UID:${e.uid}`, `DTSTAMP:${utc(e.updatedAt)}`, `SUMMARY:${escapeText(e.summary)}`);
    if (e.date) {
      lines.push(`DTSTART;VALUE=DATE:${ymd(e.date)}`, `DTEND;VALUE=DATE:${ymd(nextDay(e.date))}`);
    } else if (e.start) {
      lines.push(`DTSTART:${utc(e.start)}`, `DTEND:${utc(e.end ?? new Date(e.start.getTime() + 2 * 3600_000))}`);
    }
    if (e.location) lines.push(`LOCATION:${escapeText(e.location)}`);
    if (e.description) lines.push(`DESCRIPTION:${escapeText(e.description)}`);
    if (e.status) lines.push(`STATUS:${e.status}`);
    lines.push('END:VEVENT');
  }
  lines.push('END:VCALENDAR');
  return lines.map(fold).join('\r\n') + '\r\n';
}
