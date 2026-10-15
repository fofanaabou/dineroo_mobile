enum SuspensionReason {
  serviceQuality('SERVICE_QUALITY', 'Réclamations qualité / hygiène'),
  incompleteOrders(
    'INCOMPLETE_ORDERS',
    'Articles manquants dans les commandes livrées',
  ),
  excessivePreparationTime(
    'EXCESSIVE_PREPARATION_TIME',
    'Délais de préparation excessifs',
  ),
  unresponsiveToOrders(
    'UNRESPONSIVE_TO_ORDERS',
    "Ne répond pas aux demandes d'acceptation de commande",
  ),
  contractBreach('CONTRACT_BREACH', 'Violation des conditions générales'),
  other('OTHER', 'Autre');

  const SuspensionReason(this.apiValue, this.label);

  static const SuspensionReason fallbackForUnknownApiValue = other;

  final String apiValue;
  final String label;

  static SuspensionReason fromApiValue(String? value) {
    final normalized = value?.trim().toUpperCase();

    return SuspensionReason.values.firstWhere(
      (reason) => reason.apiValue == normalized,
      orElse: () => fallbackForUnknownApiValue,
    );
  }
}
