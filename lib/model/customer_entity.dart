class CustomerEntity {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;

  CustomerEntity({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
  });

  CustomerEntity copy({
    int id,
    String name,
    String phone,
    String email,
    String address,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}
