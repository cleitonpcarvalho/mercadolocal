class Validators {
  const Validators._();

  static String? requiredField(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field e obrigatorio';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, field: 'Email');
    if (required != null) return required;

    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Email invalido';
    }

    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, field: 'Senha');
    if (required != null) return required;

    if (value!.length < 8) {
      return 'Senha deve ter ao menos 8 caracteres';
    }

    return null;
  }
}
