/// A smart home routine (e.g. "Lock all doors", "Dim lights").
class Routine {
  final String id;
  final String name;
  final String description;
  final String iconName; // e.g. lock, lightbulb, thermometer
  final bool isEnabled;

  const Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.isEnabled = true,
  });
}
