/// Myuser object model
class Myuser {
  final String id;
  final String name;
  final String city;
  final String state;
  final String country;
  final List<String> specializations;
  final double charge;
  final String phone;
  final String email;
  final String picture;
  final Map<String, dynamic> availability;
  final String type; // not sure we need this since all Myusers are type=myuser

  const Myuser({this.id, this.name, this.city, this.state, this.country,
      this.specializations, this.charge, this.phone, this.email,
      this.picture, this.availability, this.type});

  Myuser.fromMap(Map<String, dynamic> attrs, String id) : this(
    id: id,
    name: attrs['name'],
    city: attrs['city'],
    state: attrs['state'],
    country: attrs['country'],
    specializations: new List<String>.from(attrs['specializations']),
    charge: attrs['typical_hourly_charge'].toDouble(),
    phone: attrs['phone'],
    email: attrs['email'],
    picture: attrs['picture'],
    availability: new Map<String, dynamic>.from(attrs['availability']),
    type: attrs['type']
  );
}