import '../../content/catalog.dart';

/// Presentation metadata is keyed by the canonical catalogue identity.
/// Titles, routes and activity counts always come from that catalogue.
class HomeStudio {
  final Studio studio;
  final String description;
  final Set<String> categories;
  HomeStudio(this.studio, this.description, this.categories);
  String get route => '/studio/${studio.id}';
  String get artwork => 'assets/home/${studio.id}.webp';
  int get count => studio.entries.length;
}

const _presentation = <String, (String, Set<String>)>{
  's00': (
    'Connect ideas, follow learning paths and test your understanding.',
    {},
  ),
  's01': (
    'Read precision instruments and investigate uncertainty.',
    {'Matter'},
  ),
  's02': ('Explore forces, pulleys, levers and collisions.', {'Matter'}),
  's03': (
    'Discover position, velocity and the geometry of motion.',
    {'Matter'},
  ),
  's04': (
    'Investigate inertia, acceleration and interacting forces.',
    {'Matter'},
  ),
  's05': ('Connect work, energy, power and efficiency.', {'Energy'}),
  's06': (
    'Explore gravity, orbital motion and escape speed.',
    {'Matter', 'Energy'},
  ),
  's07': ('Investigate springs, pendulums and resonance.', {'Waves'}),
  's08': ('Discover interference, sound and wave motion.', {'Waves'}),
  's09': ('Explore reflection, refraction, lenses and diffraction.', {'Waves'}),
  's10': ('Investigate charge, fields, circuits and capacitors.', {'Energy'}),
  's11': ('Explore magnetic fields, forces and induction.', {'Energy'}),
  's12': (
    'Discover semiconductors, logic and electronic sensors.',
    {'Matter', 'Energy'},
  ),
  's13': (
    'Explore temperature, heat transfer and thermal engines.',
    {'Energy'},
  ),
  's14': ('Investigate pressure, buoyancy and flowing liquids.', {'Matter'}),
  's15': (
    'Discover quantum ideas, atoms and radioactivity.',
    {'Matter', 'Waves'},
  ),
  's16': (
    'Explore planets, stars, galaxies and the expanding universe.',
    {'Waves', 'Energy'},
  ),
};

final homeStudios = List<HomeStudio>.unmodifiable(
  studios.map((s) {
    final metadata = _presentation[s.id]!;
    return HomeStudio(s, metadata.$1, metadata.$2);
  }),
);

List<HomeStudio> searchHomeStudios(String query) {
  final q = query.trim().toLowerCase();
  return homeStudios
      .where(
        (s) => '${s.studio.title} ${s.description}'.toLowerCase().contains(q),
      )
      .toList();
}

List<Entry> searchHomeLabs(String query) {
  final q = query.trim().toLowerCase();
  return allEntries
      .where(
        (e) => '${e.title} ${e.principle} ${studios[e.studioIndex].title}'
            .toLowerCase()
            .contains(q),
      )
      .toList();
}
