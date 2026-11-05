// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_sourcegraph_suppression.dart';

class SourcegraphResult {
  /// Creates a result.
  const SourcegraphResult({
    this.instance,
    this.repo,
    this.revision,
    this.queryText,
    this.resultsCount,
    this.codyModel,
    this.codyPromptTokens,
    this.codyCompletionTokens,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? instance;
  final String? repo;
  final String? revision;
  final String? queryText;
  final int? resultsCount;
  final String? codyModel;
  final int? codyPromptTokens;
  final int? codyCompletionTokens;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class SourcegraphCallResult<T> {
  /// Creates a call result.
  const SourcegraphCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final SourcegraphResult? result;
}

Future<T> tracedSourcegraph<T>({
  required String operation,
  required Future<SourcegraphCallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (sourcegraphInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_sourcegraph');
  final span = t.startSpan('sourcegraph $operation', kind: SpanKind.client);
  try {
    span.addAttributes(OTelAPI.attributes(
        [OTelAPI.attributeString('rpc.system', 'sourcegraph')]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.instance != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('sourcegraph.instance', res.instance!)]));
      }
      if (res.repo != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('sourcegraph.repo', res.repo!)]));
      }
      if (res.revision != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('vcs.ref.head.revision', res.revision!)]));
      }
      if (res.queryText != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString('sourcegraph.search.query', res.queryText!)
        ]));
      }
      if (res.resultsCount != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('sourcegraph.results.count', res.resultsCount!)
        ]));
      }
      if (res.codyModel != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('gen_ai.request.model', res.codyModel!)]));
      }
      if (res.codyPromptTokens != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt(
            'gen_ai.usage.prompt_tokens',
            res.codyPromptTokens!,
          )
        ]));
      }
      if (res.codyCompletionTokens != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt(
            'gen_ai.usage.completion_tokens',
            res.codyCompletionTokens!,
          )
        ]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString('sourcegraph.error.code', res.errorCode!)
        ]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            ErrorAttributes.errorType.key,
            res.errorCode ?? 'sourcegraph.error',
          )
        ]));
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
