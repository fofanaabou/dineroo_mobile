/// Business error codes the backend returns alongside an HTTP status, in the
/// `type` field of a guard rejection or the `code` field of an error payload.
///
/// Centralized because the same code is consumed by several exceptions: if the
/// backend renames one, the mobile app has a single place to update instead of
/// silently losing the fallback wherever a literal was restated.
enum ApiErrorCode {
  restaurantSuspended('RESTAURANT_SUSPENDED');

  const ApiErrorCode(this.apiValue);

  final String apiValue;

  bool matches(String? value) => value?.trim().toUpperCase() == apiValue;
}
