import '../../../core/network/json_reader.dart';

enum MenuItemType {
  fixed('FIXED'),
  customizable('CUSTOMIZABLE');

  final String wireValue;
  const MenuItemType(this.wireValue);

  static MenuItemType fromWire(String? value) =>
      value == 'CUSTOMIZABLE' ? MenuItemType.customizable : MenuItemType.fixed;
}

class MenuItemModel {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final MenuItemType type;
  final int priceTickets;
  final String? imageUrl;
  final bool isAvailable;
  final int? preparationTime;

  const MenuItemModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.type,
    required this.priceTickets,
    this.imageUrl,
    required this.isAvailable,
    this.preparationTime,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
    id: json.requireString('id'),
    vendorId: json.stringOr('vendorId', ''),
    name: json.requireString('name'),
    description: json.optionalString('description'),
    type: MenuItemType.fromWire(json.optionalString('type')),
    priceTickets: json.intOr('priceTickets', 0),
    imageUrl: json.optionalString('imageUrl'),
    isAvailable: json.boolOr('isAvailable', true),
    preparationTime: json.optionalInt('preparationTime'),
  );

  MenuItemModel copyWith({bool? isAvailable}) => MenuItemModel(
    id: id,
    vendorId: vendorId,
    name: name,
    description: description,
    type: type,
    priceTickets: priceTickets,
    imageUrl: imageUrl,
    isAvailable: isAvailable ?? this.isAvailable,
    preparationTime: preparationTime,
  );
}
