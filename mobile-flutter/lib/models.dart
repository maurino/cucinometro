class Member {
  final int id;
  final String name;

  const Member({required this.id, required this.name});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class Meal {
  final int id;
  final String date;
  final String kind;
  final List<String> participants;
  final String? dishwasher;

  const Meal({
    required this.id,
    required this.date,
    required this.kind,
    required this.participants,
    required this.dishwasher,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as int,
      date: json['date'] as String,
      kind: json['kind'] as String,
      participants: (json['participants'] as List<dynamic>).cast<String>(),
      dishwasher: json['dishwasher'] as String?,
    );
  }
}

class DecideDishwasherResult {
  final String dishwasher;
  final Meal meal;
  final Map<String, int> stats;
  final String? explanation;

  const DecideDishwasherResult({
    required this.dishwasher,
    required this.meal,
    required this.stats,
    required this.explanation,
  });

  factory DecideDishwasherResult.fromJson(Map<String, dynamic> json) {
    final statsRaw = (json['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return DecideDishwasherResult(
      dishwasher: json['dishwasher'] as String,
      meal: Meal.fromJson(json['meal'] as Map<String, dynamic>),
      stats: statsRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      explanation: (json['explanation'] as Map<String, dynamic>?)?['explanation'] as String?,
    );
  }
}
