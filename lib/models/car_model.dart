import 'package:cloud_firestore/cloud_firestore.dart';

enum Transmission { automatic, manual }
enum FuelType { essence, diesel, electric, hybrid }

class CarModel {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int seats;
  final Transmission transmission;
  final FuelType fuelType;
  final double pricePerDay;
  final double deposit;
  final List<String> photos;
  final String description;
  final bool isAvailable;
  final double? rating;
  final int reviewCount;
  final List<String> features;
  final DateTime createdAt;

  CarModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    required this.pricePerDay,
    required this.deposit,
    required this.photos,
    required this.description,
    this.isAvailable = true,
    this.rating,
    this.reviewCount = 0,
    this.features = const [],
    required this.createdAt,
  });

  String get fullName => '$brand $model $year';

  String get transmissionLabel =>
      transmission == Transmission.automatic ? 'Automatique' : 'Manuelle';

  String get fuelLabel {
    switch (fuelType) {
      case FuelType.essence: return 'Essence';
      case FuelType.diesel: return 'Diesel';
      case FuelType.electric: return 'Electrique';
      case FuelType.hybrid: return 'Hybride';
    }
  }

  String? get mainPhoto => photos.isNotEmpty ? photos.first : null;

  factory CarModel.fromMap(Map<String, dynamic> map, String id) {
    return CarModel(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: (map['year'] ?? DateTime.now().year) as int,
      seats: (map['seats'] ?? 5) as int,
      transmission: map['transmission'] == 'manual'
          ? Transmission.manual
          : Transmission.automatic,
      fuelType: _parseFuelType(map['fuelType']),
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      deposit: (map['deposit'] ?? 0).toDouble(),
      photos: List<String>.from(map['photos'] ?? []),
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      rating: map['rating']?.toDouble(),
      reviewCount: (map['reviewCount'] ?? 0) as int,
      features: List<String>.from(map['features'] ?? []),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CarModel.fromDoc(DocumentSnapshot doc) =>
      CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  static FuelType _parseFuelType(String? value) {
    switch (value) {
      case 'diesel': return FuelType.diesel;
      case 'electric': return FuelType.electric;
      case 'hybrid': return FuelType.hybrid;
      default: return FuelType.essence;
    }
  }

  Map<String, dynamic> toMap() => {
        'brand': brand,
        'model': model,
        'year': year,
        'seats': seats,
        'transmission': transmission.name,
        'fuelType': fuelType.name,
        'pricePerDay': pricePerDay,
        'deposit': deposit,
        'photos': photos,
        'description': description,
        'isAvailable': isAvailable,
        'rating': rating,
        'reviewCount': reviewCount,
        'features': features,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  CarModel copyWith({
    String? brand,
    String? model,
    int? year,
    int? seats,
    Transmission? transmission,
    FuelType? fuelType,
    double? pricePerDay,
    double? deposit,
    List<String>? photos,
    String? description,
    bool? isAvailable,
    List<String>? features,
  }) {
    return CarModel(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      seats: seats ?? this.seats,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      deposit: deposit ?? this.deposit,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating,
      reviewCount: reviewCount,
      features: features ?? this.features,
      createdAt: createdAt,
    );
  }
}