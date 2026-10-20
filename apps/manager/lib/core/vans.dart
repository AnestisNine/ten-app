/// Συνηθισμένα diesel βαν 9 θέσεων (οδηγός + 8) με ενδεικτική κατανάλωση WLTP.
/// Δεν υπάρχει δωρεάν API με αξιόπιστα στοιχεία κατανάλωσης για βαν, οπότε η
/// λίστα είναι ενσωματωμένη. Οι τιμές είναι ενδεικτικές (συνδυασμένος κύκλος).
class VanSpec {
  const VanSpec(this.id, this.name, this.engine, this.wltp);
  final String id;
  final String name;
  final String engine;

  /// L/100km, WLTP συνδυασμένος.
  final double wltp;

  String get label => '$name · $engine';
}

class Vans {
  /// Συντελεστής για φορτωμένο βαν (backline, 8 άτομα, αυτοκινητόδρομος).
  static const double loadedFactor = 1.15;

  static const List<VanSpec> all = [
    VanSpec('vw_t61', 'VW Transporter T6.1 Kombi/Caravelle', '2.0 TDI 110 kW', 7.9),
    VanSpec('vw_t7', 'VW Transporter T7 Caravelle', '2.0 TDI 110 kW', 7.7),
    VanSpec('mb_vito', 'Mercedes-Benz Vito Tourer', '2.0 CDI 120 kW', 7.5),
    VanSpec('mb_sprinter', 'Mercedes-Benz Sprinter 9θέσιο', '2.0 CDI 120 kW', 9.5),
    VanSpec('ford_tc', 'Ford Transit Custom Kombi', '2.0 EcoBlue 136 hp', 7.6),
    VanSpec('ford_tourneo', 'Ford Tourneo Custom', '2.0 EcoBlue 150 hp', 7.7),
    VanSpec('renault_trafic', 'Renault Trafic Combi', '2.0 dCi 150', 7.2),
    VanSpec('opel_vivaro', 'Opel Vivaro Combi', '2.0 D 145', 7.0),
    VanSpec('peugeot_traveller', 'Peugeot Traveller / Expert', '2.0 BlueHDi 145', 7.0),
    VanSpec('citroen_spacetourer', 'Citroën SpaceTourer', '2.0 BlueHDi 145', 7.0),
    VanSpec('toyota_proace', 'Toyota Proace Verso', '2.0 D-4D 144', 7.0),
    VanSpec('hyundai_staria', 'Hyundai Staria 9', '2.2 CRDi 177', 8.3),
  ];

  static const String customId = 'custom';

  static VanSpec? byId(String id) {
    for (final v in all) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Ενδεικτική κατανάλωση για φορτωμένο βαν.
  static double loaded(VanSpec v) =>
      (v.wltp * loadedFactor * 10).round() / 10;
}
