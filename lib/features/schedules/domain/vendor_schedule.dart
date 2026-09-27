import '../../../core/network/json_reader.dart';

enum Weekday {
  monday('MONDAY', 'Lundi'),
  tuesday('TUESDAY', 'Mardi'),
  wednesday('WEDNESDAY', 'Mercredi'),
  thursday('THURSDAY', 'Jeudi'),
  friday('FRIDAY', 'Vendredi'),
  saturday('SATURDAY', 'Samedi'),
  sunday('SUNDAY', 'Dimanche');

  final String wireValue;
  final String label;
  const Weekday(this.wireValue, this.label);

  static Weekday fromWire(String? value) => enumFromWire(
    value,
    Weekday.values,
    (day) => day.wireValue,
    fallback: Weekday.monday,
  );
}

class VendorSchedule {
  final String id;
  final Weekday day;
  final String startTime;
  final String endTime;

  const VendorSchedule({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  String get rangeLabel => '$startTime – $endTime';

  factory VendorSchedule.fromJson(Map<String, dynamic> json) => VendorSchedule(
    id: json.requireString('id'),
    day: Weekday.fromWire(json.optionalString('day')),
    startTime: json.stringOr('startTime', '--:--'),
    endTime: json.stringOr('endTime', '--:--'),
  );
}
