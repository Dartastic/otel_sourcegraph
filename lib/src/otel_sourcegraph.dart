// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_sourcegraph_suppression.dart';

class SourcegraphResult {
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

class SourcegraphCallResult<T> {
  const SourcegraphCallResult({required this.value, this.result});
  final T value;
  final SourcegraphResult? result;
}

Future<T> tracedSourcegraph<T>({
  required String operation,
  required Future<SourcegraphCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (sourcegraphInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_sourcegraph');
  final span = t.startSpan('sourcegraph $operation', kind: SpanKind.client);
  try {
    span.setStringAttribute('rpc.system', 'sourcegraph');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.instance != null) {
        span.setStringAttribute('sourcegraph.instance', res.instance!);
      }
      if (res.repo != null) {
        span.setStringAttribute('sourcegraph.repo', res.repo!);
      }
      if (res.revision != null) {
        span.setStringAttribute('vcs.ref.head.revision', res.revision!);
      }
      if (res.queryText != null) {
        span.setStringAttribute('sourcegraph.search.query', res.queryText!);
      }
      if (res.resultsCount != null) {
        span.setIntAttribute('sourcegraph.results.count', res.resultsCount!);
      }
      if (res.codyModel != null) {
        span.setStringAttribute('gen_ai.request.model', res.codyModel!);
      }
      if (res.codyPromptTokens != null) {
        span.setIntAttribute(
          'gen_ai.usage.prompt_tokens',
          res.codyPromptTokens!,
        );
      }
      if (res.codyCompletionTokens != null) {
        span.setIntAttribute(
          'gen_ai.usage.completion_tokens',
          res.codyCompletionTokens!,
        );
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('sourcegraph.error.code', res.errorCode!);
      }
      final fail =
          res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
          ErrorResource.errorType.key,
          res.errorCode ?? 'sourcegraph.error',
        );
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
