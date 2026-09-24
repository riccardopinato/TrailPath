import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trail_path/core/config/map_config.dart';
import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:trail_path/infrastructure/network/http_retry.dart';

class NominatimPlaceSearchService implements PlaceSearchService {
  NominatimPlaceSearchService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.minimumRequestGap = const Duration(seconds: 1),
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 5),
    NetworkDelay? delay,
    NetworkClock? clock,
  }) : assert(maxRetries >= 0),
       _client = client ?? http.Client(),
       _delay = delay ?? defaultNetworkDelay,
       _clock = clock ?? DateTime.now;

  final http.Client _client;
  final NetworkDelay _delay;
  final NetworkClock _clock;
  final Duration timeout;
  final Duration minimumRequestGap;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;
  final Map<String, List<PlaceSearchResult>> _cache = {};
  Future<void> _requestTail = Future<void>.value();
  DateTime? _lastRequestAt;

  void dispose() => _client.close();

  @override
  Future<List<PlaceSearchResult>> search(
    String query, {
    String? languageCode,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return const [];
    }

    final cacheKey = '${languageCode ?? 'en'}|${normalized.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final previousTail = _requestTail;
    final gate = Completer<void>();
    _requestTail = gate.future;
    await previousTail;

    try {
      final cachedAfterWait = _cache[cacheKey];
      if (cachedAfterWait != null) {
        return cachedAfterWait;
      }

      await _respectRateLimit();

      final uri = Uri.parse(MapConfig.searchEndpoint).replace(
        queryParameters: {
          'format': 'jsonv2',
          'q': normalized,
          'limit': '6',
          'addressdetails': '1',
        },
      );

      final response = await _request(uri, languageCode: languageCode);

      final results = decodeNominatimSearchResults(response.body);
      _cache[cacheKey] = results;

      if (_cache.length > 40) {
        _cache.remove(_cache.keys.first);
      }

      return results;
    } on TimeoutException {
      throw const PlaceSearchException('Search service timed out.');
    } on http.ClientException catch (error) {
      throw PlaceSearchException(
        'Search network request failed: ${error.message}',
      );
    } finally {
      gate.complete();
    }
  }

  Future<http.Response> _request(Uri uri, {String? languageCode}) async {
    Object? lastNetworkError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                if (!kIsWeb) 'User-Agent': MapConfig.userAgent,
                if (languageCode != null && languageCode.isNotEmpty)
                  'Accept-Language': languageCode,
              },
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response;
        }

        if (!isTransientHttpStatus(response.statusCode) ||
            attempt == maxRetries) {
          throw PlaceSearchException(
            'Search service returned HTTP ${response.statusCode}.',
          );
        }

        await _delay(_retryDelay(response, attempt));
      } on TimeoutException catch (error) {
        lastNetworkError = error;
        if (attempt == maxRetries) {
          throw PlaceSearchException(
            'Search service timed out after ${maxRetries + 1} attempts.',
          );
        }
        await _delay(_retryDelay(null, attempt));
      } on http.ClientException catch (error) {
        lastNetworkError = error;
        if (attempt == maxRetries) {
          throw PlaceSearchException(
            'Search network request failed after ${maxRetries + 1} attempts: '
            '${error.message}',
          );
        }
        await _delay(_retryDelay(null, attempt));
      }
    }

    throw PlaceSearchException('Search request failed: $lastNetworkError');
  }

  Duration _retryDelay(http.Response? response, int attempt) {
    final retryAfter = retryAfterDelay(
      response?.headers['retry-after'],
      now: _clock(),
      maxDelay: maxRetryDelay,
    );
    final computed =
        retryAfter ??
        exponentialBackoff(
          attempt: attempt,
          baseDelay: retryBaseDelay,
          maxDelay: maxRetryDelay,
        );
    return computed < minimumRequestGap ? minimumRequestGap : computed;
  }

  Future<void> _respectRateLimit() async {
    final previous = _lastRequestAt;
    if (previous != null) {
      final elapsed = _clock().difference(previous);
      if (elapsed < minimumRequestGap) {
        await _delay(minimumRequestGap - elapsed);
      }
    }
    _lastRequestAt = _clock();
  }
}

List<PlaceSearchResult> decodeNominatimSearchResults(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List) {
    throw const PlaceSearchException('Invalid place search response.');
  }

  final results = <PlaceSearchResult>[];
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) {
      continue;
    }

    final latitude = double.tryParse(item['lat']?.toString() ?? '');
    final longitude = double.tryParse(item['lon']?.toString() ?? '');
    final displayName = item['display_name']?.toString().trim() ?? '';
    final explicitName = item['name']?.toString().trim() ?? '';

    if (latitude == null ||
        longitude == null ||
        displayName.isEmpty ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      continue;
    }

    final name = explicitName.isNotEmpty
        ? explicitName
        : displayName.split(',').first.trim();

    results.add(
      PlaceSearchResult(
        name: name.isEmpty ? displayName : name,
        displayName: displayName,
        point: GeoPoint(latitude: latitude, longitude: longitude),
      ),
    );
  }

  return List<PlaceSearchResult>.unmodifiable(results);
}

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String message;

  @override
  String toString() => 'PlaceSearchException: $message';
}
