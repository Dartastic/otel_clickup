// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_clickup_suppression.dart';

const _tracerName = 'dartastic_otel_libs_clickup';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any ClickUp REST call in a CLIENT span.
Future<T> tracedClickup<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? workspaceId,
  String? taskId,
  String? listId,
}) async {
  if (clickupInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'clickup.resource': resource,
    'clickup.action': action,
    'clickup.operation': '$resource.$action',
  };
  if (workspaceId != null) m['clickup.workspace.id'] = workspaceId;
  if (taskId != null) m['clickup.task.id'] = taskId;
  if (listId != null) m['clickup.list.id'] = listId;

  final span = _tracer().startSpan(
    'clickup $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
