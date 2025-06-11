class LightRecommendationModel {
  final String chronotype;
  final double dlmo;
  final double sleepStart;
  final double sleepEnd;
  final double boostStart;
  final double boostEnd;

  LightRecommendationModel({
    required this.chronotype,
    required this.dlmo,
    required this.sleepStart,
    required this.sleepEnd,
    required this.boostStart,
    required this.boostEnd,
  });
}
