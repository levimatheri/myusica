/// Myuser object model
class User {
  final String username;
  // final String picture;
  // final Map<String, dynamic> availability;
  final String type;
  final List<String> pushTokens;

  const User({this.username, this.type, this.pushTokens});

  User.fromMap(Map<String, dynamic> attrs, String id) : this(
    username: attrs['username'],
    // id: id,
    // name: attrs['name'],
    // email: attrs['email'],
    // picture: attrs['picture'],
    // availability: new Map<String, dynamic>.from(attrs['availability']),
    type: attrs['type'],
    pushTokens: attrs['pushTokens']
  );
}