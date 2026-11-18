/// Input validation and regional phone E.164 normalization helpers.
class Validators {
  static final RegExp _e164Regex = RegExp(r'^\+[1-9]\d{7,14}$');
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  /// Converts Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹) digits to ASCII 0-9.
  static String normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const persianIndic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final arabicIdx = arabicIndic.indexOf(char);
      if (arabicIdx != -1) {
        buffer.write(arabicIdx);
        continue;
      }
      final persianIdx = persianIndic.indexOf(char);
      if (persianIdx != -1) {
        buffer.write(persianIdx);
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  /// Normalizes regional or international phone strings to canonical E.164 (e.g. `+967770000000`).
  /// Returns `null` if the input does not represent a plausible phone number.
  static String? tryNormalizePhoneE164(
    String? input, {
    String defaultCountryCode = '+967',
  }) {
    if (input == null) return null;
    final converted = normalizeDigits(input).trim();
    if (converted.isEmpty) return null;

    var cleaned = converted.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    if (cleaned.startsWith('+')) {
      final digitsOnly = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      final candidate = '+$digitsOnly';
      return isValidPhoneE164(candidate) ? candidate : null;
    }

    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    // Explicit country prefixes typed without leading '+'
    if (digits.startsWith('967') && digits.length >= 11 && digits.length <= 12) {
      return '+$digits';
    }
    if (digits.startsWith('966') && digits.length >= 11 && digits.length <= 12) {
      return '+$digits';
    }

    // Yemeni local mobile formats: 7xxxxxxxx (9 digits) or 07xxxxxxxx (10 digits)
    if (RegExp(r'^7[01378]\d{7}$').hasMatch(digits)) {
      return '+967$digits';
    }
    if (RegExp(r'^07[01378]\d{7}$').hasMatch(digits)) {
      return '+967${digits.substring(1)}';
    }

    // Saudi local mobile formats: 5xxxxxxxx (9 digits) or 05xxxxxxxx (10 digits)
    if (RegExp(r'^5\d{8}$').hasMatch(digits)) {
      return '+966$digits';
    }
    if (RegExp(r'^05\d{8}$').hasMatch(digits)) {
      return '+966${digits.substring(1)}';
    }

    // Generic local leading zero with fallback country code
    final normalizedDefault = defaultCountryCode.startsWith('+')
        ? defaultCountryCode
        : '+$defaultCountryCode';
    final localDigits = digits.startsWith('0') ? digits.substring(1) : digits;
    if (localDigits.length >= 7 && localDigits.length <= 11) {
      final candidate = '$normalizedDefault$localDigits';
      return isValidPhoneE164(candidate) ? candidate : null;
    }

    return null;
  }

  /// Normalizes [input] to E.164 or returns the trimmed original string when invalid.
  static String normalizePhoneE164(
    String input, {
    String defaultCountryCode = '+967',
  }) {
    return tryNormalizePhoneE164(
          input,
          defaultCountryCode: defaultCountryCode,
        ) ??
        normalizeDigits(input).trim();
  }

  /// Checks whether [value] conforms strictly to E.164 (`+[1-9]\d{7,14}`).
  static bool isValidPhoneE164(String? value) {
    if (value == null) return false;
    return _e164Regex.hasMatch(value.trim());
  }

  /// Checks whether [value] is a valid email address.
  static bool isValidEmail(String? value) {
    if (value == null) return false;
    return _emailRegex.hasMatch(value.trim());
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الاسم';
    }
    return null;
  }

  static String? validatePhone(
    String? value, {
    bool isRequired = false,
    String defaultCountryCode = '+967',
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired ? 'الرجاء إدخال رقم الهاتف' : null;
    }
    if (tryNormalizePhoneE164(
          trimmed,
          defaultCountryCode: defaultCountryCode,
        ) ==
        null) {
      return 'صيغة رقم الهاتف غير صحيحة (مثال: +967770000000 أو 770000000)';
    }
    return null;
  }

  static String? validatePin(String? value, {int length = 4}) {
    final converted = normalizeDigits(value ?? '').trim();
    if (!RegExp('^\\d{$length}\$').hasMatch(converted)) {
      return 'يجب إدخال رمز سري مكون من $length أرقام';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validatMatching(String? value1, String? value2) {
    if (value1 != value2) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }
}
