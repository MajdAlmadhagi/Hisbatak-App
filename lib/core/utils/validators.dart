class Validators {

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الاسم';
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