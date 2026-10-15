class DaysConstants {
  static const Map<String, String> daysMap = {
    'MONDAY': 'Lundi',
    'TUESDAY': 'Mardi',
    'WEDNESDAY': 'Mercredi',
    'THURSDAY': 'Jeudi',
    'FRIDAY': 'Vendredi',
    'SATURDAY': 'Samedi',
    'SUNDAY': 'Dimanche',
  };

  static String getDayLabel(String dayKey) {
    return daysMap[dayKey] ?? dayKey;
  }
}
