class FormValidator {
  // Validar nombre de usuario
  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'El nombre de usuario no puede estar vacío';
    } else if (username.length < 3) {
      return 'El nombre debe de ser más o igual a 3 caracteres.';
    } else if (username.length > 52) {
      return 'El nombre de usuario no puede tener más de 52 caracteres';
    }
    return null;
  }

  String? validaKey(String key) {
    if (key.isEmpty) {
      return 'El nombre de usuario no puede estar vacío';
    }
    return null;
  }

  // Validar contraseña
  String? validatePassword(String password) {
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialCharacter =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    if (password.isEmpty) {
      return 'La contraseña no puede estar vacía';
    } else if (!hasUpperCase) {
      return 'La contraseña debe contener al menos una letra mayúscula';
    } else if (!hasLowerCase) {
      return 'La contraseña debe contener al menos una letra minúscula';
    } else if (!hasSpecialCharacter) {
      return 'La contraseña debe contener al menos un carácter especial';
    } else if (!hasNumber) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  // Validar correo electrónico
  String? validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (email.isEmpty) {
      return 'El correo electrónico no puede estar vacío';
    } else if (!emailRegex.hasMatch(email)) {
      return 'El correo electrónico no tiene una estructura válida "@"';
    }
    return null;
  }

  //Validar nombre completo
  String? validateFullName(String fullName) {
    if (fullName.isEmpty) {
      return 'El nombre completo no puede estar vacío';
    } else if (!RegExp(r'^(?:[A-Z][a-z]*\s?)+$').hasMatch(fullName)) {
      return 'Cada palabra del nombre completo debe iniciar con una letra mayúscula';
    } else if (fullName.length < 3) {
      return 'El nombre debe de ser más o igual a 3 letras.';
    }
    return null;
  }

  
}
