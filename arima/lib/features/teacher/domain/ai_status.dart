class AiStatus {
  const AiStatus({
    required this.provider,
    required this.providerLabel,
    required this.mode,
    required this.ready,
    required this.selectedModel,
    required this.detail,
    this.endpoint,
  });

  final String provider;
  final String providerLabel;
  final String mode;
  final bool ready;
  final String selectedModel;
  final String? endpoint;
  final String detail;

  factory AiStatus.fromJson(Map<String, dynamic> json) {
    return AiStatus(
      provider: json['provider'] as String? ?? 'builtin',
      providerLabel: json['provider_label'] as String? ?? 'Built-in',
      mode: json['mode'] as String? ?? 'builtin',
      ready: json['ready'] as bool? ?? false,
      selectedModel: json['model'] as String? ?? '',
      endpoint: json['endpoint'] as String?,
      detail: json['detail'] as String? ?? '',
    );
  }

  factory AiStatus.unavailable(String detail) {
    return AiStatus(
      provider: 'unknown',
      providerLabel: 'AI',
      mode: 'unavailable',
      ready: false,
      selectedModel: '',
      detail: detail,
    );
  }
}
