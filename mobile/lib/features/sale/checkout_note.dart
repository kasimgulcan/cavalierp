String buildCheckoutNote({
  String? note,
  String? phone,
  String? email,
}) {
  final parts = <String>[];
  final trimmedPhone = phone?.trim();
  final trimmedEmail = email?.trim();
  final trimmedNote = note?.trim();

  if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
    parts.add('Telefon: $trimmedPhone');
  }
  if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
    parts.add('E-posta: $trimmedEmail');
  }
  if (trimmedNote != null && trimmedNote.isNotEmpty) {
    if (parts.isNotEmpty) parts.add('');
    parts.add(trimmedNote);
  }

  return parts.join('\n');
}

class ParsedCheckoutNote {
  const ParsedCheckoutNote({this.phone, this.email, this.note});

  final String? phone;
  final String? email;
  final String? note;

  bool get isEmpty =>
      (phone == null || phone!.isEmpty) &&
      (email == null || email!.isEmpty) &&
      (note == null || note!.isEmpty);
}

ParsedCheckoutNote parseCheckoutNote(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const ParsedCheckoutNote();
  }

  String? phone;
  String? email;
  final noteLines = <String>[];

  for (final line in raw.split('\n')) {
    if (line.startsWith('Telefon: ')) {
      final value = line.substring('Telefon: '.length).trim();
      if (value.isNotEmpty) phone = value;
    } else if (line.startsWith('E-posta: ')) {
      final value = line.substring('E-posta: '.length).trim();
      if (value.isNotEmpty) email = value;
    } else if (line.trim().isNotEmpty) {
      noteLines.add(line);
    }
  }

  return ParsedCheckoutNote(
    phone: phone,
    email: email,
    note: noteLines.isEmpty ? null : noteLines.join('\n'),
  );
}
