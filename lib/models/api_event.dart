class ApiEvent {
  final int id;
  final String name;
  final String venue;
  final String startDate;
  final String endDate;
  final String status;
  final int ticketsSold;
  final int capacity;
  final EventCategory? category;

  ApiEvent({
    required this.id,
    required this.name,
    required this.venue,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.ticketsSold,
    required this.capacity,
    this.category,
  });

  factory ApiEvent.fromJson(Map<String, dynamic> json) {
    return ApiEvent(
      id: json['id'] as int,
      name: json['name'] as String,
      venue: json['venue'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
      ticketsSold: json['tickets_sold'] as int? ?? 0,
      capacity: json['capacity'] as int,
      category: json['category'] != null
          ? EventCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'venue': venue,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'tickets_sold': ticketsSold,
      'capacity': capacity,
      'category': category?.toJson(),
    };
  }

  bool get isSoldOut => ticketsSold >= capacity;
  int get ticketsAvailable => capacity - ticketsSold;
}

class EventCategory {
  final int id;
  final String name;

  EventCategory({
    required this.id,
    required this.name,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
