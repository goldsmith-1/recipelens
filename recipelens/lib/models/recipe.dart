List<String> _strings(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

class Recipe {
  const Recipe({
    required this.title,
    required this.minutes,
    required this.difficulty,
    required this.uses,
    required this.missing,
    required this.steps,
  });

  final String title;
  final int minutes;
  final String difficulty;
  final List<String> uses;
  final List<String> missing;
  final List<String> steps;

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        title: (j['title'] ?? 'Untitled recipe').toString(),
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
        difficulty: (j['difficulty'] ?? 'Medium').toString(),
        uses: _strings(j['uses']),
        missing: _strings(j['missing']),
        steps: _strings(j['steps']),
      );
}

class ScanResult {
  const ScanResult({required this.ingredients, required this.recipes});

  final List<String> ingredients;
  final List<Recipe> recipes;

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        ingredients: _strings(j['ingredients']),
        recipes: (j['recipes'] is List ? j['recipes'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(Recipe.fromJson)
            .toList(),
      );
}
