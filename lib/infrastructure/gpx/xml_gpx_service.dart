import 'package:trail_path/core/domain/models.dart';
import 'package:trail_path/core/services/service_contracts.dart';
import 'package:xml/xml.dart';

class XmlGpxService implements GpxService {
  const XmlGpxService();

  @override
  Future<GpxDocument> parse(String xml) async {
    late XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlParserException catch (error) {
      throw GpxException('Invalid GPX XML: ${error.message}');
    }

    final root = document.rootElement;
    if (root.name.local.toLowerCase() != 'gpx') {
      throw const GpxException('The selected file is not a GPX document.');
    }

    final metadataName = _firstText(root, 'metadata', 'name');
    final trackName = _firstDescendantText(root, 'trk', 'name');
    final routeName = _firstDescendantText(root, 'rte', 'name');
    final name = _cleanName(
      metadataName ?? trackName ?? routeName ?? 'Imported GPX',
    );

    var points = _parsePoints(root, 'trkpt');
    if (points.length < 2) {
      points = _parsePoints(root, 'rtept');
    }
    if (points.length < 2) {
      points = _parsePoints(root, 'wpt');
    }

    if (points.length < 2) {
      throw const GpxException(
        'The GPX file does not contain a usable route or track.',
      );
    }

    return GpxDocument(name: name, points: List<GeoPoint>.unmodifiable(points));
  }

  @override
  Future<String> export(GpxDocument document) async {
    if (document.points.length < 2) {
      throw const GpxException('A GPX export requires at least two points.');
    }

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'gpx',
      nest: () {
        builder.attribute('version', '1.1');
        builder.attribute('creator', 'TrailPath');
        builder.attribute('xmlns', 'http://www.topografix.com/GPX/1/1');
        builder.attribute(
          'xmlns:xsi',
          'http://www.w3.org/2001/XMLSchema-instance',
        );
        builder.attribute(
          'xsi:schemaLocation',
          'http://www.topografix.com/GPX/1/1 '
              'http://www.topografix.com/GPX/1/1/gpx.xsd',
        );

        builder.element(
          'metadata',
          nest: () {
            builder.element('name', nest: document.name);
            builder.element(
              'time',
              nest: DateTime.now().toUtc().toIso8601String(),
            );
          },
        );

        builder.element(
          'trk',
          nest: () {
            builder.element('name', nest: document.name);
            builder.element(
              'trkseg',
              nest: () {
                for (final point in document.points) {
                  builder.element(
                    'trkpt',
                    attributes: {
                      'lat': point.latitude.toStringAsFixed(7),
                      'lon': point.longitude.toStringAsFixed(7),
                    },
                    nest: () {
                      final elevation = point.elevationMeters;
                      if (elevation != null) {
                        builder.element(
                          'ele',
                          nest: elevation.toStringAsFixed(1),
                        );
                      }

                      final timestamp = point.timestamp;
                      if (timestamp != null) {
                        builder.element(
                          'time',
                          nest: timestamp.toUtc().toIso8601String(),
                        );
                      }
                    },
                  );
                }
              },
            );
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  List<GeoPoint> _parsePoints(XmlElement root, String localName) {
    final points = <GeoPoint>[];

    for (final element in root.descendants.whereType<XmlElement>()) {
      if (element.name.local != localName) {
        continue;
      }

      final latitude = double.tryParse(element.getAttribute('lat') ?? '');
      final longitude = double.tryParse(element.getAttribute('lon') ?? '');
      if (latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      double? elevation;
      DateTime? timestamp;

      for (final child in element.childElements) {
        switch (child.name.local) {
          case 'ele':
            elevation = double.tryParse(child.innerText.trim());
          case 'time':
            timestamp = DateTime.tryParse(child.innerText.trim());
        }
      }

      points.add(
        GeoPoint(
          latitude: latitude,
          longitude: longitude,
          elevationMeters: elevation,
          timestamp: timestamp,
        ),
      );
    }

    return points;
  }

  String? _firstText(XmlElement root, String parent, String child) {
    for (final element in root.childElements) {
      if (element.name.local != parent) {
        continue;
      }
      for (final nested in element.childElements) {
        if (nested.name.local == child) {
          final value = nested.innerText.trim();
          return value.isEmpty ? null : value;
        }
      }
    }
    return null;
  }

  String? _firstDescendantText(XmlElement root, String parent, String child) {
    for (final element in root.descendants.whereType<XmlElement>()) {
      if (element.name.local != parent) {
        continue;
      }
      for (final nested in element.childElements) {
        if (nested.name.local == child) {
          final value = nested.innerText.trim();
          return value.isEmpty ? null : value;
        }
      }
    }
    return null;
  }

  String _cleanName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Imported GPX';
    }
    return trimmed.length <= 120 ? trimmed : trimmed.substring(0, 120);
  }
}

class GpxException implements Exception {
  const GpxException(this.message);

  final String message;

  @override
  String toString() => 'GpxException: $message';
}
