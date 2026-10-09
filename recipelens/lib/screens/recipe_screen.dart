import 'package:flutter/material.dart';

import '../models/recipe.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${recipe.minutes} min  |  ${recipe.difficulty}', style: t.textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('From your photo', style: t.textTheme.titleSmall),
          Wrap(spacing: 8, children: [for (final u in recipe.uses) Chip(label: Text(u))]),
          if (recipe.missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('You will also need', style: t.textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              for (final m in recipe.missing) Chip(label: Text(m), backgroundColor: t.colorScheme.tertiaryContainer),
            ]),
          ],
          const SizedBox(height: 20),
          Text('Method', style: t.textTheme.titleMedium),
          for (var i = 0; i < recipe.steps.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
              title: Text(recipe.steps[i]),
            ),
        ],
      ),
    );
  }
}
