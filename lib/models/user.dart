class User {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String licenseNumber; // Numéro d'ordre des médecins
  final String specialty;
  final String region;

  User({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.specialty,
    required this.region,
  });

  // Convertir en Map pour Firebase ou autre base de données
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'specialty': specialty,
      'region': region,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
