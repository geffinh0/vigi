import 'dart:ui' show Locale;

import 'package:geocoding/geocoding.dart';

/// Transforma coordenadas em um endereço aproximado.
///
/// "Lat: -23.5505, Lng: -46.6333" não significa nada para quem está com
/// medo; "Perto de Rua Augusta, 1200, Consolação" significa.
// A interface existe para os testes trocarem a implementação nativa.
// ignore: one_member_abstracts
abstract class AddressResolver {
  /// Endereço aproximado, sem o "Perto de", ou `null` se não foi possível
  /// descobrir (sem internet, sem serviço de geocodificação).
  Future<String?> near(double latitude, double longitude);
}

/// Implementação com o geocodificador do próprio sistema (pacote geocoding).
class GeocodingAddressResolver implements AddressResolver {
  const GeocodingAddressResolver();

  @override
  Future<String?> near(double latitude, double longitude) async {
    try {
      final placemarks =
          await Geocoding(
                locale: const Locale('pt', 'BR'),
              )
              .placemarkFromCoordinates(latitude, longitude)
              .timeout(
                const Duration(seconds: 6),
              );
      if (placemarks.isEmpty) return null;
      return formatPlacemark(
        street: placemarks.first.thoroughfare,
        number: placemarks.first.subThoroughfare,
        neighborhood: placemarks.first.subLocality,
        city: placemarks.first.locality,
      );
    } catch (_) {
      return null;
    }
  }

  /// "Rua Augusta, 1200, Consolação". Sem rua, usa o bairro e a cidade.
  static String? formatPlacemark({
    String? street,
    String? number,
    String? neighborhood,
    String? city,
  }) {
    String? clean(String? value) {
      final v = value?.trim() ?? '';
      return v.isEmpty ? null : v;
    }

    final parts = <String>[
      ?clean(street),
      if (clean(street) != null) ?clean(number),
      ?clean(neighborhood),
    ];
    if (parts.isEmpty) return clean(city);
    if (clean(street) == null && clean(city) != null) parts.add(clean(city)!);
    return parts.join(', ');
  }
}
