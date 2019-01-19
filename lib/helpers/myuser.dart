class Myuser {
  final String id;
  final String name;
  final String city;
  final String state;
  final List<String> specializations;
  final int charge;
  final Map<String, dynamic> availability;
  final String type;

  const Myuser({this.id, this.name, this.city, this.state,
      this.specializations, this.charge, this.availability, this.type});

  Myuser.fromMap(Map<String, dynamic> attrs, String id) : this(
    id: id,
    name: attrs['name'],
    city: attrs['city'],
    state: attrs['state'],
    specializations: new List<String>.from(attrs['specializations']),
    charge: attrs['typical_hourly_charge'],
    availability: new Map<String, dynamic>.from(attrs['availability']),
    type: attrs['type']
  );

  // Future<String> coordinatesFromCityState(String cityName, String stateName) async {
  //   final query = cityName + ", " + stateName;
  //   var addresses = await Geocoder.local.findAddressesFromQuery(query);
  //   var first = addresses.first;

  //   return first.coordinates.toString();
  // }
}