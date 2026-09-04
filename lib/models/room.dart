class BookingItem {
  String bookingId;
  String bookedBy;
  String date; // YYYY-MM-DD
  String startTime; // HH:MM
  String endTime; // HH:MM
  String purpose;

  BookingItem({
    required this.bookingId,
    required this.bookedBy,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) => BookingItem(
    bookingId: json['booking_id']?.toString() ?? '',
    bookedBy: json['booked_by']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    startTime: json['start_time']?.toString() ?? '',
    endTime: json['end_time']?.toString() ?? '',
    purpose: json['purpose']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'booked_by': bookedBy,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'purpose': purpose,
  };
}

class RoomItem {
  String id;
  String roomNumber;
  String type; // "classroom" | "lab" | "seminar"
  int capacity;
  List<String> equipment;
  int floor;
  String status; // "available" | "unavailable"
  List<BookingItem> bookings;

  RoomItem({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.capacity,
    required this.equipment,
    required this.floor,
    required this.status,
    required this.bookings,
  });

  factory RoomItem.fromJson(Map<String, dynamic> json) => RoomItem(
    id: json['id']?.toString() ?? '',
    roomNumber: json['room_number']?.toString() ?? '',
    type: json['type']?.toString() ?? 'classroom',
    capacity: (json['capacity'] is num)
        ? (json['capacity'] as num).toInt()
        : int.tryParse(json['capacity'].toString()) ?? 0,
    equipment: (json['equipment'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    floor: (json['floor'] is num)
        ? (json['floor'] as num).toInt()
        : int.tryParse(json['floor'].toString()) ?? 1,
    status: json['status']?.toString() ?? 'available',
    bookings: (json['bookings'] as List<dynamic>?)
            ?.map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_number': roomNumber,
    'type': type,
    'capacity': capacity,
    'equipment': equipment,
    'floor': floor,
    'status': status,
    'bookings': bookings.map((b) => b.toJson()).toList(),
  };

  RoomItem copyWith({
    String? id,
    String? roomNumber,
    String? type,
    int? capacity,
    List<String>? equipment,
    int? floor,
    String? status,
    List<BookingItem>? bookings,
  }) {
    return RoomItem(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      equipment: equipment ?? this.equipment,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
    );
  }
}
