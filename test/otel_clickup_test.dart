// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_clickup/otel_clickup.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_clickup-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('task.create records CLIENT span', () async {
    await tracedClickup<String>(
      resource: 'task',
      action: 'create',
      workspaceId: 'w-1',
      listId: 'l-1',
      invoke: () async => 't-1',
    );
    final a = attrsOf(spans.findSpanByName('clickup task.create')!);
    expect(a['clickup.resource'], 'task');
    expect(a['clickup.action'], 'create');
    expect(a['clickup.operation'], 'task.create');
    expect(a['clickup.workspace.id'], 'w-1');
    expect(a['clickup.list.id'], 'l-1');
  });

  test('suppression skips spans', () async {
    await runWithoutClickupInstrumentationAsync(() async {
      await tracedClickup<String>(
        resource: 'task',
        action: 'create',
        invoke: () async => 't',
      );
    });
    expect(spans.findSpansStartingWith('clickup '), isEmpty);
  });
}
