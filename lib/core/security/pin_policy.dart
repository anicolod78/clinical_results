/// Requisiti minimi del codice di sicurezza.
///
/// Un PIN numerico ha per natura poca entropia: si può solo evitare che
/// l'utente scelga proprio le combinazioni che un attaccante prova per prime.
/// I controlli restano volutamente pochi e comprensibili, perché una regola
/// che l'utente non capisce lo porta ad annotarsi il PIN da qualche parte,
/// peggiorando la sicurezza invece di migliorarla.
library;

class PinPolicy {
  const PinPolicy._();

  static const minLength = 6;
  static const maxLength = 12;

  /// Sequenze banali, in avanti e all'indietro.
  static const _sequences = '0123456789';

  /// Restituisce `null` se il PIN è accettabile, altrimenti il motivo del
  /// rifiuto, già scritto per essere mostrato all'utente.
  static String? validate(String pin) {
    if (pin.isEmpty) return 'Inserisci un codice di sicurezza.';
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return 'Il codice deve contenere solo cifre.';
    }
    if (pin.length < minLength) {
      return 'Servono almeno $minLength cifre.';
    }
    if (pin.length > maxLength) {
      return 'Il codice non può superare $maxLength cifre.';
    }
    if (_allSameDigit(pin)) {
      return 'Evita un codice con tutte le cifre uguali.';
    }
    if (_isSequential(pin)) {
      return 'Evita una sequenza di cifre consecutive.';
    }
    if (_isRepeatedPattern(pin)) {
      return 'Evita un codice formato da un gruppo di cifre ripetuto.';
    }
    return null;
  }

  static bool isValid(String pin) => validate(pin) == null;

  static bool _allSameDigit(String pin) =>
      pin.split('').every((c) => c == pin[0]);

  static bool _isSequential(String pin) {
    final reversed = String.fromCharCodes(_sequences.codeUnits.reversed);
    // La sequenza ciclica copre anche casi come "890123".
    final forward = '$_sequences$_sequences';
    final backward = '$reversed$reversed';
    return forward.contains(pin) || backward.contains(pin);
  }

  /// Riconosce codici come "123123" o "1212 12", banali quanto le sequenze.
  static bool _isRepeatedPattern(String pin) {
    for (var size = 1; size <= pin.length ~/ 2; size++) {
      if (pin.length % size != 0) continue;
      final unit = pin.substring(0, size);
      if (unit * (pin.length ~/ size) == pin) return true;
    }
    return false;
  }
}
