# RecipeLens

Snap a photo of what is in your kitchen and get recipe ideas. RecipeLens sends the photo to an AI vision model (Anthropic Claude or Google Gemini), identifies the ingredients, and suggests three recipes with step-by-step methods, plus a list of extra ingredients you would need.

Built with Flutter. Works on Android and iOS.

## Features
- Take a photo or pick one from the gallery
- Ingredient detection and recipe suggestions from either **Claude** or **Gemini** (switch in the app when both keys are set)
- Dietary filters: vegetarian, vegan, gluten-free, dairy-free
- Each recipe shows time, difficulty, what you already have, what is missing, and a numbered method
- Defensive parsing of model replies, with clear error messages for network, key and format problems
- Unit tests for the response parser, and a CI workflow that runs `flutter analyze` and `flutter test`

## Setup
1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone the repo and generate the platform folders (they are not committed):
   ```bash
   git clone https://github.com/<your-username>/recipelens.git
   cd recipelens
   flutter create . --project-name recipelens --platforms=android,ios
   flutter pub get
   ```
3. Add your keys. Copy `secrets.example.json` to `secrets.json` (it is git-ignored) and fill in one or both keys.
4. Run:
   ```bash
   flutter run --dart-define-from-file=secrets.json
   ```
   Optional overrides: `CLAUDE_MODEL` and `GEMINI_MODEL` in the same file. Check each provider's docs for current model names.

### Permissions
- **iOS:** add these keys to `ios/Runner/Info.plist`: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`, each with a short reason such as "Used to photograph your ingredients".
- **Android:** `image_picker` works without extra setup for the gallery. For the camera, add `<uses-permission android:name="android.permission.CAMERA"/>` to `android/app/src/main/AndroidManifest.xml` if your device requires it.

## Security note
Keys passed with `--dart-define` are compiled into the app and can be extracted from a released build. This is fine for local development and demos. For a published app, call the AI provider from your own backend and keep the keys there.

## Project structure
```
lib/
  main.dart                    app entry and theme
  models/recipe.dart           Recipe and ScanResult, tolerant JSON parsing
  services/vision_service.dart Claude and Gemini requests, prompt, response parsing
  screens/home_screen.dart     photo input, filters, results
  screens/recipe_screen.dart   recipe detail
test/vision_service_test.dart  parser tests
```

## Roadmap
- Backend proxy for API keys
- Save favourite recipes locally
- Edit the detected ingredient list before generating recipes
- Nutrition estimates and serving size scaling

## License
MIT. See [LICENSE](LICENSE).
