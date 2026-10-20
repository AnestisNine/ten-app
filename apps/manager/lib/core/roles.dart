/// Display names of the app roles (see packages/shared/src/roles.ts).
String roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Admin';
    case 'manager':
      return 'Manager';
    case 'member':
      return 'Μέλος';
    case 'accountant':
      return 'Λογιστής';
    case 'merchManager':
      return 'Merch manager';
    case 'merchStaff':
      return 'Merch (POS)';
    case 'socialManager':
      return 'Social media';
    default:
      return role;
  }
}
