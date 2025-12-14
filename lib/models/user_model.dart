// User Model - Represents user data structure for the Declutter app
class User {
  // User's unique identifier
  final String id;

  // User's full name
  final String name;

  // User's email address
  final String email;

  // User's password (should be hashed in production)
  final String password;

  // Timestamp when user account was created
  final DateTime createdAt;

  // Constructor to create a User instance with required fields
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  // CopyWith method - Creates a copy of User with some fields replaced
  // Useful for updating user data without creating a new instance
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Override toString for better debugging output
  @override
  String toString() => 'User(id: $id, name: $name, email: $email, createdAt: $createdAt)';

  // Override equality operator to compare User objects
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.password == password &&
        other.createdAt == createdAt;
  }

  // Override hashCode for use in collections
  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode ^ password.hashCode ^ createdAt.hashCode;
}
