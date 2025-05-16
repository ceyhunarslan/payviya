class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email gerekli';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    
    if (value.length < 6) {
      return 'Şifre en az 6 haneli olmalı';
    }
    
    if (value.length > 8) {
      return 'Şifre en fazla 8 haneli olabilir';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Şifre sadece rakam içermeli';
    }
    
    return null;
  }

  static String? validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Doğrulama kodu gerekli';
    }
    if (value.length != 6) {
      return 'Doğrulama kodu 6 haneli olmalı';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Doğrulama kodu sadece rakam içermeli';
    }
    return null;
  }
} 