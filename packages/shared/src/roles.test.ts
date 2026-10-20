import { describe, expect, it } from 'vitest';
import { can, parseRoles, requiresTwoFactor } from './roles.js';

describe('roles', () => {
  it('parses comma separated roles and drops unknown ones', () => {
    expect(parseRoles('member, socialManager,hacker')).toEqual(['member', 'socialManager']);
    expect(parseRoles(null)).toEqual([]);
  });

  it('admin can do everything, including sensitive member data', () => {
    expect(can(['admin'], 'membersSensitive', 'read')).toBe(true);
    expect(can(['admin'], 'users', 'delete')).toBe(true);
  });

  it('accountant is read-only', () => {
    expect(can(['accountant'], 'finance', 'read')).toBe(true);
    expect(can(['accountant'], 'finance', 'write')).toBe(false);
  });

  it('nobody but admin reads sensitive member data', () => {
    for (const role of ['manager', 'member', 'accountant', 'merchManager', 'merchStaff', 'socialManager'] as const) {
      expect(can([role], 'membersSensitive', 'read')).toBe(false);
    }
  });

  it('merch staff cannot see customers or finance', () => {
    expect(can(['merchStaff'], 'customers', 'read')).toBe(false);
    expect(can(['merchStaff'], 'finance', 'read')).toBe(false);
  });

  it('combines multiple roles', () => {
    expect(can(['member', 'merchManager'], 'orders', 'write')).toBe(true);
  });

  it('requires 2FA for admin, manager, accountant and social manager only', () => {
    expect(requiresTwoFactor(['member'])).toBe(false);
    expect(requiresTwoFactor(['merchStaff', 'merchManager'])).toBe(false);
    expect(requiresTwoFactor(['member', 'socialManager'])).toBe(true);
    expect(requiresTwoFactor(['accountant'])).toBe(true);
  });
});
