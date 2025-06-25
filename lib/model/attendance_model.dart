import 'package:hive/hive.dart';

part 'attendance_model.g.dart';

@HiveType(typeId: 0)
class AttendanceModel extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  DateTime? checkIn;

  @HiveField(2)
  DateTime? checkOut;

  @HiveField(3)
  double? checkInLatitude;

  @HiveField(4)
  double? checkInLongitude;

  @HiveField(5)
  double? checkOutLatitude;

  @HiveField(6)
  double? checkOutLongitude;

    @HiveField(7)
  String? date;

  AttendanceModel({
    this.name,
    this.checkIn,
    this.checkOut,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.date,
  });

  @override
  String toString() {
    return '''
AttendanceModel(
  name: $name, 
  checkIn: $checkIn, 
  checkOut: $checkOut,
  checkInLatLng: ($checkInLatitude, $checkInLongitude),
  checkOutLatLng: ($checkOutLatitude, $checkOutLongitude),
  date : $date
)''';
  }
}

