import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/branding/data/admin_branding_repository.dart';

class AdminPlacePrediction {
  const AdminPlacePrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
}

class AdminPlaceLocation {
  const AdminPlaceLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.locality,
    this.city,
  });

  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  final String? locality;
  final String? city;
}

class AdminPlacesService {
  AdminPlacesService();

  String? _apiKey = 'AIzaSyBhuUTfle47F2pikumX3W5s99IHq0IIm3U';
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 MatchMateAdmin/1.0',
        'Accept': 'application/json',
      },
    ),
  );

  final Map<String, AdminPlaceLocation> _locationCache = {};

  void setApiKey(String key) {
    if (key.trim().isNotEmpty) _apiKey = key.trim();
  }

  Future<List<AdminPlacePrediction>> autocomplete(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    // 1. Try Google Places (New and Legacy)
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      try {
        final googleResults = await _googlePlacesAutocomplete(cleanQuery);
        if (googleResults.isNotEmpty) return googleResults;
      } catch (e) {
        debugPrint('[AdminPlacesService] Google Places API error: $e');
      }
    }

    // 2. Resilient fallback: OpenStreetMap (Photon + Nominatim)
    return _osmAutocomplete(cleanQuery);
  }

  Future<AdminPlaceLocation?> fetchPlaceDetails(String placeId) async {
    final cleanId = placeId.trim();
    if (cleanId.isEmpty) return null;

    if (_locationCache.containsKey(cleanId)) {
      return _locationCache[cleanId];
    }

    if (_apiKey != null && _apiKey!.isNotEmpty && !cleanId.startsWith('osm_')) {
      try {
        final details = await _googleFetchPlace(cleanId);
        if (details != null) {
          _locationCache[cleanId] = details;
          return details;
        }
      } catch (e) {
        debugPrint('[AdminPlacesService] Google Place Details error: $e');
      }
    }

    return null;
  }

  Future<List<AdminPlacePrediction>> _googlePlacesAutocomplete(
    String query,
  ) async {
    // 1a. Places API (New)
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: {'input': query},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
          },
          validateStatus: (status) => (status ?? 500) < 500,
        ),
      );

      if (response.statusCode == 200) {
        final suggestions =
            response.data?['suggestions'] as List<dynamic>? ?? const [];
        if (suggestions.isNotEmpty) {
          final results = <AdminPlacePrediction>[];
          for (final s in suggestions) {
            final p =
                (s as Map<String, dynamic>)['placePrediction']
                    as Map<String, dynamic>?;
            if (p == null) continue;
            final placeId =
                p['placeId'] as String? ?? p['place'] as String? ?? '';
            final structured = p['structuredFormat'] as Map<String, dynamic>?;
            final primaryText =
                (structured?['mainText'] as Map<String, dynamic>?)?['text']
                    as String? ??
                '';
            final secondaryText =
                (structured?['secondaryText'] as Map<String, dynamic>?)?['text']
                    as String? ??
                '';
            final fullText =
                (p['text'] as Map<String, dynamic>?)?['text'] as String? ??
                primaryText;

            results.add(
              AdminPlacePrediction(
                placeId: placeId,
                primaryText: primaryText,
                secondaryText: secondaryText,
                fullText: fullText,
              ),
            );
          }
          if (results.isNotEmpty) return results;
        }
      }
    } catch (_) {}

    // 1b. Legacy Places API
    try {
      final legacy = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {'input': query, 'key': _apiKey},
        options: Options(validateStatus: (status) => (status ?? 500) < 500),
      );
      if (legacy.data?['status'] == 'OK') {
        final predictions =
            legacy.data?['predictions'] as List<dynamic>? ?? const [];
        return predictions.map((p) {
          final map = p as Map<String, dynamic>;
          final formatting =
              map['structured_formatting'] as Map<String, dynamic>?;
          return AdminPlacePrediction(
            placeId: map['place_id'] as String? ?? '',
            primaryText:
                formatting?['main_text'] as String? ??
                map['description'] as String? ??
                '',
            secondaryText: formatting?['secondary_text'] as String? ?? '',
            fullText: map['description'] as String? ?? '',
          );
        }).toList();
      }
    } catch (_) {}

    return const [];
  }

  Future<AdminPlaceLocation?> _googleFetchPlace(String placeId) async {
    final cleanId = placeId.startsWith('places/')
        ? placeId.replaceFirst('places/', '')
        : placeId;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://places.googleapis.com/v1/places/$cleanId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'id,displayName,formattedAddress,location,addressComponents',
          },
          validateStatus: (status) => (status ?? 500) < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final loc = data['location'] as Map<String, dynamic>?;
        final lat = (loc?['latitude'] as num?)?.toDouble();
        final lng = (loc?['longitude'] as num?)?.toDouble();
        final name =
            (data['displayName'] as Map<String, dynamic>?)?['text'] as String?;
        final address = data['formattedAddress'] as String?;

        if (lat != null && lng != null) {
          return AdminPlaceLocation(
            latitude: lat,
            longitude: lng,
            name: name,
            address: address,
            locality: name,
            city: address?.split(',').last.trim(),
          );
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<AdminPlacePrediction>> _osmAutocomplete(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://photon.komoot.io/api/',
        queryParameters: {'q': query, 'limit': 8},
      );

      final features = response.data?['features'] as List<dynamic>? ?? const [];
      final results = <AdminPlacePrediction>[];

      for (var i = 0; i < features.length; i++) {
        final f = features[i] as Map<String, dynamic>;
        final props = f['properties'] as Map<String, dynamic>? ?? {};
        final geom = f['geometry'] as Map<String, dynamic>? ?? {};
        final coords = geom['coordinates'] as List<dynamic>? ?? [];

        if (coords.length < 2) continue;

        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();

        final name = props['name'] as String? ?? query;
        final parts = <String>[];
        if (props['street'] != null) parts.add(props['street'] as String);
        if (props['district'] != null) parts.add(props['district'] as String);
        if (props['city'] != null) parts.add(props['city'] as String);
        if (props['state'] != null) parts.add(props['state'] as String);

        final secondaryText = parts.join(', ');
        final fullText = secondaryText.isNotEmpty
            ? '$name, $secondaryText'
            : name;
        final placeId = 'osm_${props['osm_type']}_${props['osm_id'] ?? i}';

        _locationCache[placeId] = AdminPlaceLocation(
          latitude: lat,
          longitude: lng,
          name: name,
          address: fullText,
          locality: name,
          city: props['city'] as String? ?? props['state'] as String?,
        );

        results.add(
          AdminPlacePrediction(
            placeId: placeId,
            primaryText: name,
            secondaryText: secondaryText,
            fullText: fullText,
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint('[AdminPlacesService] OSM error: $e');
      return const [];
    }
  }
}

final adminPlacesServiceProvider = Provider<AdminPlacesService>((ref) {
  final service = AdminPlacesService();
  ref
      .watch(adminBrandingRepositoryProvider)
      .getBranding()
      .then((branding) {
        if (branding.googleMapsApiKey != null &&
            branding.googleMapsApiKey!.isNotEmpty) {
          service.setApiKey(branding.googleMapsApiKey!);
        }
      })
      .catchError((_) {});
  return service;
});
