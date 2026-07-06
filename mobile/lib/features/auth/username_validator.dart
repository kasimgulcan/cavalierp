final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{2,50}$');

String? validateUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) return 'Kullanıcı adı gerekli';
  if (username.length < 2) return 'En az 2 karakter olmalı';
  if (username.length > 50) return 'En fazla 50 karakter olabilir';
  if (!_usernamePattern.hasMatch(username)) {
    return 'Yalnızca harf, rakam ve alt çizgi kullanılabilir';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Şifre gerekli';
  if (password.length < 2) return 'En az 2 karakter olmalı';
  return null;
}

String? validatePasswordConfirmation(String? value, String newPassword) {
  final confirmation = value ?? '';
  if (confirmation.isEmpty) return 'Şifre tekrarı gerekli';
  if (confirmation != newPassword) return 'Şifreler eşleşmiyor';
  return null;
}
