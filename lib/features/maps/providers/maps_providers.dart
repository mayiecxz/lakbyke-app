import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/features/maps/data/repositories/maps_repository.dart';

/// Provider for MapsRepository (singleton)
final mapsRepositoryProvider = Provider<MapsRepository>((ref) {
  return MapsRepository();
});
