// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class User {
  String name;
  String national_id;
  String identifier;
  String password;
  int role_id;
  User({
    required this.name,
    required this.national_id,
    required this.identifier,
    required this.password,
    required this.role_id,
  });

  User copyWith({
    String? name,
    String? national_id,
    String? identifier,
    String? password,
    int? role_id,
  }) {
    return User(
      name: name ?? this.name,
      national_id: national_id ?? this.national_id,
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      role_id: role_id ?? this.role_id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'national_id': national_id,
      'identifier': identifier,
      'password': password,
      'role_id': role_id,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      national_id: map['national_id'] as String,
      identifier: map['identifier'] as String,
      password: map['password'] as String,
      role_id: map['role_id'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(name: $name, national_id: $national_id, identifier: $identifier, password: $password, role_id: $role_id)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.national_id == national_id &&
        other.identifier == identifier &&
        other.password == password &&
        other.role_id == role_id;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        national_id.hashCode ^
        identifier.hashCode ^
        password.hashCode ^
        role_id.hashCode;
  }
}
