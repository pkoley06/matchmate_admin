class QuestionnaireOption {
  const QuestionnaireOption({
    required this.value,
    required this.label,
    required this.description,
  });

  final String value;
  final String label;
  final String description;

  factory QuestionnaireOption.fromJson(Map<String, dynamic> json) =>
      QuestionnaireOption(
        value: (json['value'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
      );
}

class QuestionnaireCategory {
  const QuestionnaireCategory({
    required this.key,
    required this.title,
    required this.headline,
    required this.description,
    required this.weight,
    required this.isDealbreaker,
    required this.options,
  });

  final String key;
  final String title;
  final String headline;
  final String description;
  final double weight;
  final bool isDealbreaker;
  final List<QuestionnaireOption> options;

  factory QuestionnaireCategory.fromJson(Map<String, dynamic> json) =>
      QuestionnaireCategory(
        key: (json['key'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        headline: (json['headline'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
        isDealbreaker: json['isDealbreaker'] as bool? ?? false,
        options: (json['options'] as List<dynamic>? ?? [])
            .map((e) => QuestionnaireOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class QuestionnaireWeights {
  const QuestionnaireWeights({
    required this.cleanlinessWeight,
    required this.sleepWeight,
    required this.guestWeight,
    required this.dietWeight,
    required this.smokingDealbreaker,
  });

  final double cleanlinessWeight;
  final double sleepWeight;
  final double guestWeight;
  final double dietWeight;
  final bool smokingDealbreaker;

  factory QuestionnaireWeights.fromJson(Map<String, dynamic> json) =>
      QuestionnaireWeights(
        cleanlinessWeight:
            (json['cleanlinessWeight'] as num?)?.toDouble() ?? 2.0,
        sleepWeight: (json['sleepWeight'] as num?)?.toDouble() ?? 1.5,
        guestWeight: (json['guestWeight'] as num?)?.toDouble() ?? 1.2,
        dietWeight: (json['dietWeight'] as num?)?.toDouble() ?? 1.0,
        smokingDealbreaker: json['smokingDealbreaker'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'cleanlinessWeight': cleanlinessWeight,
        'sleepWeight': sleepWeight,
        'guestWeight': guestWeight,
        'dietWeight': dietWeight,
        'smokingDealbreaker': smokingDealbreaker,
      };
}

class AdminQuestionnaireOverview {
  const AdminQuestionnaireOverview({
    required this.categories,
    required this.currentWeights,
  });

  final List<QuestionnaireCategory> categories;
  final QuestionnaireWeights currentWeights;

  factory AdminQuestionnaireOverview.fromJson(Map<String, dynamic> json) =>
      AdminQuestionnaireOverview(
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map(
              (e) => QuestionnaireCategory.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        currentWeights: json['currentWeights'] != null
            ? QuestionnaireWeights.fromJson(
                json['currentWeights'] as Map<String, dynamic>,
              )
            : const QuestionnaireWeights(
                cleanlinessWeight: 2.0,
                sleepWeight: 1.5,
                guestWeight: 1.2,
                dietWeight: 1.0,
                smokingDealbreaker: true,
              ),
      );
}
