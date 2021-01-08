class Forecast {
  final String updated;
  final Map<String, dynamic> location;
  final String type;
  final List<ForecastData> forecastData;

  Forecast({
    this.updated,
    this.location,
    this.type,
    this.forecastData,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      updated: json["updated"],
      location: json["location"],
      type: json["type"],
      forecastData: (json["forecast"] as List).map((e) => ForecastData.fromJson(e)).toList(),
    );
  }
}

class ForecastData {
  final String date;
  final int earlyMorningProbStart;
  final int earlyMorningProbEnd;
  final int morningProbStart;
  final int morningProbEnd;
  final int afternoonProbStart;
  final int afternoonProbEnd;
  final int nightProbStart;
  final int nightProbEnd;

  ForecastData({
    this.date,
    this.earlyMorningProbStart,
    this.earlyMorningProbEnd,
    this.morningProbStart,
    this.morningProbEnd,
    this.afternoonProbStart,
    this.afternoonProbEnd,
    this.nightProbStart,
    this.nightProbEnd,
  });

  static int valueOrNull(Map<String, dynamic> json, String timeOfDay, bool start) {
    final time = json[timeOfDay];
    if(time == null) {
      return null;
    }
    final probability = time["rain_prob_range"];
    if(probability == null) {
      return null;
    }
    return start? probability[0] : probability[1];
  }

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      date: json["date"],
      earlyMorningProbStart: valueOrNull(json, "early_morning", true),
      earlyMorningProbEnd: valueOrNull(json, "early_morning", false),
      morningProbStart: valueOrNull(json, "morning", true),
      morningProbEnd: valueOrNull(json, "morning", false),
      afternoonProbStart: valueOrNull(json, "afternoon", true),
      afternoonProbEnd: valueOrNull(json, "afternoon", false),
      nightProbStart: valueOrNull(json, "night", true),
      nightProbEnd: valueOrNull(json, "night", false),
    );
  }
}


