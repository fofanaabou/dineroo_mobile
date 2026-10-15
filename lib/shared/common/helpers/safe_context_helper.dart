import 'package:flutter/widgets.dart';

typedef ContextCallback = void Function(BuildContext context);

Future<void> safeCallWithContext({
  required State state,
  required Future<void> Function() asyncOperation,
  required ContextCallback onSuccess,
  ContextCallback? onError,
  ContextCallback? onComplete,
}) async {
  try {
    await asyncOperation();

    if (!state.mounted) return;
    onSuccess(state.context);
  } catch (e) {
    if (state.mounted && onError != null) {
      onError(state.context);
    }
  } finally {
    if (state.mounted && onComplete != null) {
      onComplete(state.context);
    }
  }
}
