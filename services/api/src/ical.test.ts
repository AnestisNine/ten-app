import { describe, expect, it } from 'vitest';
import { buildCalendar } from './ical.js';

describe('buildCalendar', () => {
  const updatedAt = new Date('2026-10-01T12:00:00Z');
  it('writes all-day and timed events with CRLF line endings', () => {
    const out = buildCalendar('TBN', [
      { uid: 'a@tbn', summary: 'Live; Athens, GR', date: '2026-12-31', updatedAt },
      { uid: 'b@tbn', summary: 'Πρόβα', start: new Date('2026-11-04T18:00:00Z'), updatedAt },
    ]);
    expect(out).toContain('SUMMARY:Live\; Athens\\, GR\r\n');
    expect(out).toContain('DTSTART;VALUE=DATE:20261231\r\nDTEND;VALUE=DATE:20270101');
    expect(out).toContain('DTSTART:20261104T180000Z\r\nDTEND:20261104T200000Z');
    expect(out.endsWith('END:VCALENDAR\r\n')).toBe(true);
  });
  it('folds long lines at 75 octets without splitting UTF-8 characters', () => {
    const out = buildCalendar('TBN', [{ uid: 'c@tbn', summary: 'Ε'.repeat(100), date: '2026-01-01', updatedAt }]);
    for (const line of out.split('\r\n')) expect(Buffer.byteLength(line)).toBeLessThanOrEqual(75);
    expect(out).toContain('\r\n Ε');
  });
});
