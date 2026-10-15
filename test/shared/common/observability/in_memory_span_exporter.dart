import 'package:opentelemetry/sdk.dart' show ReadOnlySpan, SpanExporter;

/// Keeps the exported spans in memory so tests can assert on what would reach the collector.
class InMemorySpanExporter implements SpanExporter {
  final List<ReadOnlySpan> spans = [];

  @override
  void export(List<ReadOnlySpan> spans) => this.spans.addAll(spans);

  @override
  void forceFlush() {}

  @override
  void shutdown() {}
}
