import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LocationQuery extends StatefulWidget {
  _LocationQueryState createState() => _LocationQueryState();
}

class _LocationQueryState extends State<LocationQuery> {
  List<Candidates> list = new List();
  var isLoading = false;
  
  _fetchData() async {
    setState(() {
      isLoading = true;
    });
    final response = 
        await http.get('https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=637%20Circle%20Hill%20Rd%20SE&inputtype=textquery&fields=formatted_address,name&key=AIzaSyCvu_XwzNjF33uBV5kS9XHJdpUMnqooFrA');

    if (response.statusCode == 200) {
      //debugPrint(json.decode(response.body)['candidates'][0]['formatted_address'].toString());
      //return;
      list = (json.decode(response.body)['candidates'] as List)
              .map((data) => new Candidates.from(data)).toList();
      setState(() {
        isLoading = false;
      });
    } else throw Exception('Failed to load addresses');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location"),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RaisedButton(
              child: new Text("Fetch data"),
              onPressed: _fetchData,
          ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
          )
          : ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, int index) {
              return ListTile(
                contentPadding: EdgeInsets.all(10.0),
                title: new Text(list[index].address),
              );
            }
          ),
    );
  }
}

class Candidates {
  final String address;
  final String name;

  Candidates._({this.address, this.name});

  factory Candidates.from(Map<String, dynamic> json) {
    return new Candidates._(
      address: json['formatted_address'],
      name: json['name'],
    );
  }
}

//class Photo {
//  final String title;
//  final String thumbnailUrl;
//
//  Photo._({this.title, this.thumbnailUrl});
//
//  factory Photo.fromJson(Map<String, dynamic> json) {
//    return new Photo._(
//      title: json['title'],
//      thumbnailUrl: json['thumbnailUrl'],
//    );
//  }
//}