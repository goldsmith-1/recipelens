import 'package:flutter_test/flutter_test.dart';
import 'package:recipelens/services/vision_service.dart';

void main() {
  const json = '{"ingredients":["egg","tomato"],"recipes":[{"title":"Shakshuka","minutes":20,"difficulty":"Easy","uses":["egg","tomato"],"missing":["onion"],"steps":["Fry","Simmer"]}]}';

  test('parses plain JSON', () {
    final r = VisionService.parse(json);
    expect(r.ingredients, ['egg', 'tomato']);
    expect(r.recipes.single.title, 'Shakshuka');
    expect(r.recipes.single.missing, ['onion']);
  });

  test('parses JSON wrapped in a code fence', () {
    final r = VisionService.parse('```json\n$json\n```');
    expect(r.recipes.length, 1);
  });

  test('rejects replies without JSON', () {
    expect(() => VisionService.parse('Sorry, I cannot help'), throwsA(isA<VisionException>()));
  });
}
