class Validators {
  const Validators._();

  static String? requiredField(String? value, {String label = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label e obrigatorio';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, label: 'Email');
    if (required != null) return required;

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Email invalido';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, label: 'Senha');
    if (required != null) return required;

    if (value!.length < 8) {
      return 'Senha deve ter ao menos 8 caracteres';
    }
    return null;
  }

  static String? phone(String? value) {
    final required = requiredField(value, label: 'Telefone');
    if (required != null) return required;

    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Telefone invalido';
    }
    return null;
  }
}
