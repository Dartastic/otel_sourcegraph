# otel_sourcegraph

Dartastic OpenTelemetry bridge for Sourcegraph (code search + intelligence + Cody).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_sourcegraph/otel_sourcegraph.dart';

await tracedSourcegraph<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return SourcegraphCallResult(value: r, result: SourcegraphResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutSourcegraphInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
