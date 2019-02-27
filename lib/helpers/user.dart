/// Myuser object model
class User {
  final String id;
  final String name;
  final String email;
  final String picture;
  final Map<String, dynamic> availability;
  final String type; // not sure we need this since all Myusers are type=myuser

  const User({this.id, this.name, this.email,
      this.picture, this.availability, this.type});

  User.fromMap(Map<String, dynamic> attrs, String id) : this(
    id: id,
    name: attrs['name'],
    email: attrs['email'],
    picture: attrs['picture'],
    availability: new Map<String, dynamic>.from(attrs['availability']),
    type: attrs['type']
  );
}