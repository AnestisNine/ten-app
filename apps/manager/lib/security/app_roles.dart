enum AppRole {
  admin,
  bandMember,
  bookingManager,
  merchManager,
  accountant,
}

String appRoleLabel(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return 'Admin';
    case AppRole.bandMember:
      return 'Band Member';
    case AppRole.bookingManager:
      return 'Booking Manager';
    case AppRole.merchManager:
      return 'Merch Manager';
    case AppRole.accountant:
      return 'Accountant';
  }
}
