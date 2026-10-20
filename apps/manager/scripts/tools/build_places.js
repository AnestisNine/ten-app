#!/usr/bin/env node
/**
 * Builds assets/data/places.json (European countries + UK, cities >= 5000 people).
 *
 *   cd scripts/tools && npm install all-the-cities && node build_places.js
 *
 * Source: GeoNames via the `all-the-cities` npm package (CC BY 4.0).
 * Output format (compact on purpose):
 *   countries: [[cc, englishName, greekName, [searchAliases...]], ...]
 *   cities:    [[name, cc, lat, lon, population, greekAlias?], ...]  (sorted by population desc)
 */
const fs = require('fs');
const path = require('path');
const cities = require('all-the-cities');

const MIN_POP = 5000;

// cc, English name, Greek name, extra search aliases
const COUNTRIES = [
  ['AL', 'Albania', 'Αλβανία', []],
  ['AD', 'Andorra', 'Ανδόρα', []],
  ['AT', 'Austria', 'Αυστρία', []],
  ['BE', 'Belgium', 'Βέλγιο', []],
  ['BA', 'Bosnia and Herzegovina', 'Βοσνία-Ερζεγοβίνη', ['Bosnia']],
  ['BG', 'Bulgaria', 'Βουλγαρία', []],
  ['HR', 'Croatia', 'Κροατία', []],
  ['CY', 'Cyprus', 'Κύπρος', []],
  ['CZ', 'Czechia', 'Τσεχία', ['Czech Republic']],
  ['DK', 'Denmark', 'Δανία', []],
  ['EE', 'Estonia', 'Εσθονία', []],
  ['FI', 'Finland', 'Φινλανδία', []],
  ['FR', 'France', 'Γαλλία', []],
  ['DE', 'Germany', 'Γερμανία', []],
  ['GR', 'Greece', 'Ελλάδα', []],
  ['HU', 'Hungary', 'Ουγγαρία', []],
  ['IS', 'Iceland', 'Ισλανδία', []],
  ['IE', 'Ireland', 'Ιρλανδία', []],
  ['IT', 'Italy', 'Ιταλία', []],
  ['XK', 'Kosovo', 'Κοσσυφοπέδιο', []],
  ['LV', 'Latvia', 'Λετονία', []],
  ['LI', 'Liechtenstein', 'Λιχτενστάιν', []],
  ['LT', 'Lithuania', 'Λιθουανία', []],
  ['LU', 'Luxembourg', 'Λουξεμβούργο', []],
  ['MT', 'Malta', 'Μάλτα', []],
  ['MD', 'Moldova', 'Μολδαβία', []],
  ['MC', 'Monaco', 'Μονακό', []],
  ['ME', 'Montenegro', 'Μαυροβούνιο', []],
  ['NL', 'Netherlands', 'Ολλανδία', ['Holland', 'Κάτω Χώρες']],
  ['MK', 'North Macedonia', 'Βόρεια Μακεδονία', ['Macedonia', 'FYROM']],
  ['NO', 'Norway', 'Νορβηγία', []],
  ['PL', 'Poland', 'Πολωνία', []],
  ['PT', 'Portugal', 'Πορτογαλία', []],
  ['RO', 'Romania', 'Ρουμανία', []],
  ['SM', 'San Marino', 'Άγιος Μαρίνος', []],
  ['RS', 'Serbia', 'Σερβία', []],
  ['SK', 'Slovakia', 'Σλοβακία', []],
  ['SI', 'Slovenia', 'Σλοβενία', []],
  ['ES', 'Spain', 'Ισπανία', []],
  ['SE', 'Sweden', 'Σουηδία', []],
  ['CH', 'Switzerland', 'Ελβετία', []],
  ['GB', 'United Kingdom', 'Ηνωμένο Βασίλειο', ['Αγγλία', 'England', 'UK', 'Scotland', 'Σκωτία', 'Wales', 'Ουαλία', 'Britain', 'Great Britain', 'Βρετανία']],
];

// Greek city names are transliterated with accents in GeoNames ("Thessaloníki").
// Strip them, and use the usual English exonyms for a few.
const GR_RENAME = {
  'Pátra': 'Patras', 'Irákleion': 'Heraklion', 'Lárisa': 'Larissa',
  'Kérkyra': 'Corfu', 'Ródos': 'Rhodes', 'Kórinthos': 'Corinth', 'Thívai': 'Thiva',
  'Ermoúpolis': 'Ermoupoli', 'Véroia': 'Veria',
};

// English exonyms for cities that GeoNames lists under their local name.
const EN_RENAME = {
  'DE:Köln': 'Cologne', 'DE:Nürnberg': 'Nuremberg', 'IT:Padova': 'Padua', 'ES:Sevilla': 'Seville',
  'BE:Antwerpen': 'Antwerp', 'BE:Gent': 'Ghent', 'CH:Genève': 'Geneva', 'SE:Göteborg': 'Gothenburg',
  'IS:Reykjavík': 'Reykjavik', 'RO:Timişoara': 'Timișoara',
};

// "CC:Dataset name" -> Greek alias (for search + display hint)
const EL = {
  'GR:Athens': 'Αθήνα', 'GR:Thessaloniki': 'Θεσσαλονίκη', 'GR:Patras': 'Πάτρα', 'GR:Piraeus': 'Πειραιάς',
  'GR:Heraklion': 'Ηράκλειο', 'GR:Larissa': 'Λάρισα', 'GR:Volos': 'Βόλος', 'GR:Ioannina': 'Ιωάννινα',
  'GR:Chania': 'Χανιά', 'GR:Kavala': 'Καβάλα', 'GR:Alexandroupoli': 'Αλεξανδρούπολη', 'GR:Serres': 'Σέρρες',
  'GR:Kalamata': 'Καλαμάτα', 'GR:Xanthi': 'Ξάνθη', 'GR:Komotini': 'Κομοτηνή', 'GR:Rethymno': 'Ρέθυμνο',
  'GR:Corfu': 'Κέρκυρα', 'GR:Rhodes': 'Ρόδος', 'GR:Agrinio': 'Αγρίνιο', 'GR:Katerini': 'Κατερίνη',
  'GR:Trikala': 'Τρίκαλα', 'GR:Lamia': 'Λαμία', 'GR:Chalkida': 'Χαλκίδα', 'GR:Kozani': 'Κοζάνη',
  'GR:Veria': 'Βέροια', 'GR:Drama': 'Δράμα', 'GR:Tripoli': 'Τρίπολη', 'GR:Sparti': 'Σπάρτη',
  'GR:Kalamaria': 'Καλαμαριά', 'GR:Peristeri': 'Περιστέρι', 'GR:Kallithea': 'Καλλιθέα', 'GR:Glyfada': 'Γλυφάδα',
  'GR:Nafplio': 'Ναύπλιο', 'GR:Corinth': 'Κόρινθος', 'GR:Kos': 'Κως', 'GR:Chios': 'Χίος', 'GR:Mytilene': 'Μυτιλήνη',
  'GR:Karditsa': 'Καρδίτσα', 'GR:Preveza': 'Πρέβεζα', 'GR:Arta': 'Άρτα', 'GR:Florina': 'Φλώρινα',
  'GR:Edessa': 'Έδεσσα', 'GR:Naousa': 'Νάουσα', 'GR:Giannitsa': 'Γιαννιτσά', 'GR:Orestiada': 'Ορεστιάδα',
  'GR:Didymoteicho': 'Διδυμότειχο', 'GR:Thiva': 'Θήβα', 'GR:Livadeia': 'Λειβαδιά', 'GR:Amaliada': 'Αμαλιάδα',
  'GR:Pyrgos': 'Πύργος', 'GR:Ermoupoli': 'Ερμούπολη',
  'AL:Tirana': 'Τίρανα', 'AL:Durrës': 'Δυρράχιο', 'AL:Vlorë': 'Αυλώνα', 'AL:Shkodër': 'Σκόδρα',
  'AL:Gjirokastër': 'Αργυρόκαστρο', 'AL:Korçë': 'Κορυτσά',
  'MK:Skopje': 'Σκόπια', 'MK:Bitola': 'Μοναστήρι', 'MK:Ohrid': 'Οχρίδα',
  'BG:Sofia': 'Σόφια', 'BG:Plovdiv': 'Φιλιππούπολη', 'BG:Varna': 'Βάρνα', 'BG:Burgas': 'Βουργάς',
  'RS:Belgrade': 'Βελιγράδι', 'RS:Novi Sad': 'Νόβι Σαντ', 'RS:Niš': 'Νις',
  'RO:Bucharest': 'Βουκουρέστι', 'RO:Cluj-Napoca': 'Κλουζ-Ναπόκα', 'RO:Timișoara': 'Τιμισοάρα',
  'HU:Budapest': 'Βουδαπέστη', 'AT:Vienna': 'Βιέννη', 'AT:Graz': 'Γκρατς', 'AT:Salzburg': 'Σάλτσμπουργκ',
  'CZ:Prague': 'Πράγα', 'CZ:Brno': 'Μπρνο', 'SK:Bratislava': 'Μπρατισλάβα',
  'DE:Berlin': 'Βερολίνο', 'DE:Munich': 'Μόναχο', 'DE:Hamburg': 'Αμβούργο', 'DE:Cologne': 'Κολωνία',
  'DE:Frankfurt am Main': 'Φρανκφούρτη', 'DE:Stuttgart': 'Στουτγκάρδη', 'DE:Dresden': 'Δρέσδη',
  'DE:Leipzig': 'Λειψία', 'DE:Nuremberg': 'Νυρεμβέργη', 'DE:Düsseldorf': 'Ντίσελντορφ', 'DE:Hannover': 'Αννόβερο',
  'DE:Bremen': 'Βρέμη', 'DE:Dortmund': 'Ντόρτμουντ',
  'IT:Rome': 'Ρώμη', 'IT:Milan': 'Μιλάνο', 'IT:Naples': 'Νάπολη', 'IT:Turin': 'Τορίνο', 'IT:Venice': 'Βενετία',
  'IT:Florence': 'Φλωρεντία', 'IT:Bologna': 'Μπολόνια', 'IT:Bari': 'Μπάρι', 'IT:Genoa': 'Γένοβα',
  'IT:Palermo': 'Παλέρμο', 'IT:Verona': 'Βερόνα', 'IT:Brindisi': 'Μπρίντιζι', 'IT:Ancona': 'Αγκώνα',
  'IT:Trieste': 'Τεργέστη', 'IT:Padua': 'Πάδοβα', 'IT:Catania': 'Κατάνια', 'IT:Pisa': 'Πίζα',
  'FR:Paris': 'Παρίσι', 'FR:Lyon': 'Λυών', 'FR:Marseille': 'Μασσαλία', 'FR:Nice': 'Νίκαια',
  'FR:Toulouse': 'Τουλούζη', 'FR:Bordeaux': 'Μπορντό', 'FR:Strasbourg': 'Στρασβούργο', 'FR:Lille': 'Λιλ',
  'ES:Madrid': 'Μαδρίτη', 'ES:Barcelona': 'Βαρκελώνη', 'ES:Seville': 'Σεβίλλη', 'ES:Valencia': 'Βαλένθια',
  'ES:Bilbao': 'Μπιλμπάο', 'ES:Málaga': 'Μάλαγα',
  'PT:Lisbon': 'Λισαβόνα', 'PT:Porto': 'Πόρτο',
  'GB:London': 'Λονδίνο', 'GB:Manchester': 'Μάντσεστερ', 'GB:Edinburgh': 'Εδιμβούργο', 'GB:Glasgow': 'Γλασκώβη',
  'GB:Liverpool': 'Λίβερπουλ', 'GB:Birmingham': 'Μπέρμιγχαμ', 'GB:Bristol': 'Μπρίστολ', 'GB:Leeds': 'Λιντς',
  'GB:Cardiff': 'Κάρντιφ', 'GB:Belfast': 'Μπέλφαστ', 'GB:Newcastle upon Tyne': 'Νιούκασλ',
  'IE:Dublin': 'Δουβλίνο',
  'NL:Amsterdam': 'Άμστερνταμ', 'NL:Rotterdam': 'Ρότερνταμ', 'NL:Utrecht': 'Ουτρέχτη',
  'BE:Brussels': 'Βρυξέλλες', 'BE:Antwerp': 'Αμβέρσα', 'BE:Ghent': 'Γάνδη',
  'CH:Zürich': 'Ζυρίχη', 'CH:Geneva': 'Γενεύη', 'CH:Bern': 'Βέρνη', 'CH:Basel': 'Βασιλεία',
  'DK:Copenhagen': 'Κοπεγχάγη', 'SE:Stockholm': 'Στοκχόλμη', 'SE:Gothenburg': 'Γκέτεμποργκ',
  'NO:Oslo': 'Όσλο', 'FI:Helsinki': 'Ελσίνκι', 'PL:Warsaw': 'Βαρσοβία', 'PL:Kraków': 'Κρακοβία',
  'HR:Zagreb': 'Ζάγκρεμπ', 'HR:Split': 'Σπλιτ', 'SI:Ljubljana': 'Λιουμπλιάνα',
  'BA:Sarajevo': 'Σαράγεβο', 'ME:Podgorica': 'Ποντγκόριτσα', 'XK:Pristina': 'Πρίστινα',
  'CY:Nicosia': 'Λευκωσία', 'CY:Limassol': 'Λεμεσός', 'CY:Larnaca': 'Λάρνακα', 'CY:Paphos': 'Πάφος',
  'MT:Valletta': 'Βαλέτα', 'IS:Reykjavik': 'Ρέικιαβικ',
  'LT:Vilnius': 'Βίλνιους', 'LV:Riga': 'Ρίγα', 'EE:Tallinn': 'Ταλίν', 'LU:Luxembourg': 'Λουξεμβούργο',
};

function stripAccents(s) {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '');
}

const ccSet = new Set(COUNTRIES.map((c) => c[0]));
const out = [];
for (const c of cities) {
  if (!ccSet.has(c.country) || c.population < MIN_POP) continue;
  let name = c.name;
  if (c.country === 'GR') {
    name = GR_RENAME[name] || stripAccents(name);
  }
  name = EN_RENAME[`${c.country}:${name}`] || name;
  const lon = Math.round(c.loc.coordinates[0] * 1000) / 1000;
  const lat = Math.round(c.loc.coordinates[1] * 1000) / 1000;
  out.push({ name, cc: c.country, lat, lon, pop: c.population });
}

// Cities that have a Greek alias but fall below MIN_POP are still wanted: handled by threshold, report them.
const seen = new Set(out.map((c) => `${c.cc}:${c.name}`));
const missing = Object.keys(EL).filter((k) => !seen.has(k));

// Drop exact duplicates (same cc + name + <3 km apart), keep the bigger one.
out.sort((a, b) => b.pop - a.pop);
const kept = [];
const byKey = new Map();
for (const c of out) {
  const k = `${c.cc}:${c.name}`;
  const list = byKey.get(k) || [];
  const dup = list.some((o) => Math.abs(o.lat - c.lat) < 0.03 && Math.abs(o.lon - c.lon) < 0.04);
  if (dup) continue;
  list.push(c);
  byKey.set(k, list);
  kept.push(c);
}

const rows = kept.map((c) => {
  const el = EL[`${c.cc}:${c.name}`];
  const row = [c.name, c.cc, c.lat, c.lon, c.pop];
  if (el) row.push(el);
  return row;
});

const json = JSON.stringify({ v: 1, countries: COUNTRIES, cities: rows });
const target = path.resolve(__dirname, '../../assets/data/places.json');
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, json);

const perCountry = {};
kept.forEach((c) => (perCountry[c.cc] = (perCountry[c.cc] || 0) + 1));
console.log(`cities: ${rows.length}, size: ${(json.length / 1024).toFixed(0)} KB`);
console.log('countries without cities:', COUNTRIES.filter((c) => !perCountry[c[0]]).map((c) => c[0]));
console.log('Greek aliases not matched to a dataset name:', missing);
