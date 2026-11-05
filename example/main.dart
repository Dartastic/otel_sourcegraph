// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_sourcegraph/otel_sourcegraph.dart';

/// Traces Sourcegraph calls with OpenTelemetry.
///
/// `otel_sourcegraph` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Sourcegraph call in
/// [tracedSourcegraph]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'sourcegraph-example');

  // Traces a Sourcegraph call.
  final sourcegraphId = await tracedSourcegraph<String>(
    operation: 'create',
    invoke: () async {
      // Make the Sourcegraph call here, then report what it returned.
      const id = 'sourcegraph_8f3a2c';
      return const SourcegraphCallResult(
          value: id,
          result: SourcegraphResult(
              instance: 'example',
              repo: 'example',
              revision: 'example',
              queryText: 'example',
              resultsCount: 3,
              codyModel: 'standard',
              codyPromptTokens: 128,
              codyCompletionTokens: 128,
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedSourcegraph create returned $sourcegraphId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSourcegraphInstrumentationAsync.
  await runWithoutSourcegraphInstrumentationAsync(
    () => tracedSourcegraph<String>(
      operation: 'create',
      invoke: () async {
        const id = 'sourcegraph_8f3a2c';
        return const SourcegraphCallResult(
            value: id,
            result: SourcegraphResult(
                instance: 'example',
                repo: 'example',
                revision: 'example',
                queryText: 'example',
                resultsCount: 3,
                codyModel: 'standard',
                codyPromptTokens: 128,
                codyCompletionTokens: 128,
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
