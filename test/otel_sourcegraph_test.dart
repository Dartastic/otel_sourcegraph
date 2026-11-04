// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_sourcegraph/otel_sourcegraph.dart';
import 'package:test/test.dart';

void main() {
  group('otel_sourcegraph', () {
    test('suppression toggles in zone', () async {
      expect(sourcegraphInstrumentationSuppressed(), isFalse);
      await runWithoutSourcegraphInstrumentationAsync(() async {
        expect(sourcegraphInstrumentationSuppressed(), isTrue);
      });
      expect(sourcegraphInstrumentationSuppressed(), isFalse);
    });

    test('SourcegraphResult fields default null', () {
      const r = SourcegraphResult();
      expect(r.statusCode, isNull);
    });
  });
}
