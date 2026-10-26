import 'package:flutter/material.dart';

const navy = Color(0xff08265b),
    cobalt = Color(0xff006eff),
    teal = Color(0xff00777d),
    muted = Color(0xff65758b);
ThemeData physicsTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: cobalt,
    primary: cobalt,
    surface: Colors.white,
    onSurface: navy,
  ),
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'sans-serif',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -.5,
      color: navy,
    ),
    headlineMedium: TextStyle(
      fontSize: 23,
      fontWeight: FontWeight.w800,
      letterSpacing: -.7,
      color: navy,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: navy,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: navy,
    ),
    bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: navy),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    foregroundColor: navy,
    centerTitle: true,
    toolbarHeight: 56,
    titleTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: navy,
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: cobalt,
    inactiveTrackColor: Color(0xffd3ddeb),
    thumbColor: cobalt,
    trackHeight: 3,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: navy,
      side: const BorderSide(color: Color(0xffcbdced)),
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: cobalt,
      minimumSize: const Size(48, 48),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: Color(0xffedf3ff),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xffe3e9f1)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffdbe3ee)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: padding, child: child),
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: teal,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.7,
    ),
  );
}

class Paragraph extends StatelessWidget {
  final String title, body;
  const Paragraph(this.title, this.body, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 7),
        Text(body),
      ],
    ),
  );
}
