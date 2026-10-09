import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe.dart';
import '../services/vision_service.dart';
import 'recipe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _diets = ['Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free'];
  final _picker = ImagePicker();
  final _service = VisionService();
  final Set<String> _diet = {};
  AiProvider? _provider = VisionService.available.isEmpty ? null : VisionService.available.first;
  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  bool _busy = false;
  String? _error;
  ScanResult? _result;

  Future<void> _pick(ImageSource source) async {
    try {
      final f = await _picker.pickImage(source: source, maxWidth: 1280, imageQuality: 80);
      if (f == null) return;
      final b = await f.readAsBytes();
      setState(() {
        _bytes = b;
        _mime = f.mimeType ?? 'image/jpeg';
        _result = null;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Could not open the camera or gallery. Check app permissions.');
    }
  }

  Future<void> _analyze() async {
    if (_bytes == null || _provider == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _service.analyze(_bytes!, _mime, _provider!, diet: _diet.toList());
      setState(() => _result = r);
      if (r.recipes.isEmpty) setState(() => _error = 'No ingredients found. Try a clearer, closer photo.');
    } on VisionException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('RecipeLens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_provider == null)
            Card(
              color: t.colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No API key found. Run the app with --dart-define-from-file=secrets.json (see README).'),
              ),
            ),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _bytes == null
                  ? ColoredBox(
                      color: t.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Text('Add a photo of your ingredients')),
                    )
                  : Image.memory(_bytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Camera'))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final d in _diets)
              FilterChip(label: Text(d), selected: _diet.contains(d), onSelected: (v) => setState(() => v ? _diet.add(d) : _diet.remove(d))),
          ]),
          if (VisionService.available.length > 1) ...[
            const SizedBox(height: 12),
            SegmentedButton<AiProvider>(
              segments: const [ButtonSegment(value: AiProvider.claude, label: Text('Claude')), ButtonSegment(value: AiProvider.gemini, label: Text('Gemini'))],
              selected: {_provider!},
              onSelectionChanged: (s) => setState(() => _provider = s.first),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _bytes == null || _provider == null || _busy ? null : _analyze,
            child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Find recipes'),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: t.colorScheme.error))),
          if (_result != null && _result!.recipes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('I can see', style: t.textTheme.titleMedium),
            Wrap(spacing: 8, children: [for (final i in _result!.ingredients) Chip(label: Text(i))]),
            const SizedBox(height: 16),
            Text('Recipe ideas', style: t.textTheme.titleMedium),
            for (final r in _result!.recipes)
              Card(
                child: ListTile(
                  title: Text(r.title),
                  subtitle: Text('${r.minutes} min, ${r.difficulty}, ${r.missing.length} extra ingredient${r.missing.length == 1 ? '' : 's'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeScreen(recipe: r))),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
