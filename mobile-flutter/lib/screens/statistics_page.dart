import 'package:flutter/material.dart';

import '../models.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.meals});

  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    final stats = _buildStats(meals);
    if (stats.isEmpty) {
      return const Center(
        child: Text('Nessuna statistica disponibile.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final row = stats[index];
        final participants = row.participants.join(', ');
        final counters = row.dishwashingCounts.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participants, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Pasti insieme: ${row.totalMeals}'),
                const SizedBox(height: 8),
                const Text('Lavaggi:'),
                ...counters.map((c) => Text('- ${c.key}: ${c.value}')),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: stats.length,
    );
  }
}

class ComboStats {
  final List<String> participants;
  final int totalMeals;
  final Map<String, int> dishwashingCounts;

  ComboStats({
    required this.participants,
    required this.totalMeals,
    required this.dishwashingCounts,
  });
}

List<ComboStats> _buildStats(List<Meal> meals) {
  final map = <String, ComboStats>{};

  for (final meal in meals) {
    if (meal.participants.isEmpty) {
      continue;
    }

    final sortedParticipants = [...meal.participants]..sort();
    final key = sortedParticipants.join('|');

    map.putIfAbsent(
      key,
      () => ComboStats(
        participants: sortedParticipants,
        totalMeals: 0,
        dishwashingCounts: {for (final p in sortedParticipants) p: 0},
      ),
    );

    final current = map[key]!;

    map[key] = ComboStats(
      participants: current.participants,
      totalMeals: current.totalMeals + 1,
      dishwashingCounts: {
        ...current.dishwashingCounts,
        if (meal.dishwasher != null && current.dishwashingCounts.containsKey(meal.dishwasher))
          meal.dishwasher!: (current.dishwashingCounts[meal.dishwasher!] ?? 0) + 1,
      },
    );
  }

  final list = map.values.toList();
  list.sort((a, b) {
    final byMeals = b.totalMeals.compareTo(a.totalMeals);
    if (byMeals != 0) {
      return byMeals;
    }
    final byLength = a.participants.length.compareTo(b.participants.length);
    if (byLength != 0) {
      return byLength;
    }
    return a.participants.join(',').compareTo(b.participants.join(','));
  });

  return list;
}
