import 'package:flutter_test/flutter_test.dart';
import 'package:trail_path/infrastructure/gpx/xml_gpx_service.dart';

void main() {
  const service = XmlGpxService();

  test('parses namespaced GPX track with elevation and time', () async {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata><name>Mountain Loop</name></metadata>
  <trk>
    <name>Ignored fallback</name>
    <trkseg>
      <trkpt lat="45.0000" lon="11.0000"><ele>100.5</ele><time>2026-09-22T10:00:00Z</time></trkpt>
      <trkpt lat="45.0100" lon="11.0100"><ele>130.0</ele><time>2026-09-22T10:10:00Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

    final document = await service.parse(xml);

    expect(document.name, 'Mountain Loop');
    expect(document.points, hasLength(2));
    expect(document.points.first.elevationMeters, 100.5);
    expect(document.points.last.timestamp?.toUtc().year, 2026);
  });

  test('falls back to route points when track points are absent', () async {
    const xml = '''
<gpx version="1.1">
  <rte>
    <name>Road Route</name>
    <rtept lat="45.0" lon="11.0"/>
    <rtept lat="45.1" lon="11.1"/>
  </rte>
</gpx>
''';

    final document = await service.parse(xml);

    expect(document.name, 'Road Route');
    expect(document.points, hasLength(2));
  });

  test('exports and reparses a GPX document', () async {
    const source = '''
<gpx version="1.1">
  <trk><name>Roundtrip</name><trkseg>
    <trkpt lat="45.0" lon="11.0"><ele>100</ele></trkpt>
    <trkpt lat="45.1" lon="11.1"><ele>120</ele></trkpt>
  </trkseg></trk>
</gpx>
''';

    final parsed = await service.parse(source);
    final exported = await service.export(parsed);
    final reparsed = await service.parse(exported);

    expect(exported, contains('creator="TrailPath"'));
    expect(reparsed.name, 'Roundtrip');
    expect(reparsed.points, hasLength(2));
    expect(reparsed.points.last.elevationMeters, 120);
  });

  test('rejects GPX files without usable route points', () async {
    await expectLater(
      service.parse('<gpx version="1.1"><metadata/></gpx>'),
      throwsA(isA<GpxException>()),
    );
  });
}
