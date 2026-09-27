class PointHistory {
  final String event;
  final String date;
  final String points;

  PointHistory({
    required this.event,
    required this.date,
    required this.points,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      event: json['event'] ?? json['description'] ?? '',
      date: json['date'] ?? json['created_at'] ?? '',
      points: json['points'] ?? json['amount']?.toString() ?? '0',
    );
  }
}
