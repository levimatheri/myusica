import 'package:flutter/material.dart';

import 'package:myusica/helpers/access.dart';
import 'package:myusica/helpers/auth.dart';
import 'package:myusica/helpers/myuser_item.dart';
import 'package:myusica/helpers/myuser.dart';
import 'package:myusica/subs/criteria.dart';

import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


/// ==========RESULTS FROM DATABASE SEARCH================
class Results extends StatefulWidget {
  final Access access;
  final String id;
  final BaseAuth auth;
  final List<Map<String, dynamic>> chats;
  Results({this.access, this.id, this.auth, this.chats});
  ResultsState createState() => new ResultsState();
}

class ResultsState extends State<Results> {
  /// Build the myuser results based on the stream from the database
  /// Filter by location and availability from the stream
  static String currCoordinates;
  static var availability;

  List<Widget> myuserItems = new List<Widget>();

  /// check if availabilities pass
  bool _areAvailabilitiesSame(Map<String, dynamic> myuserAvail, 
                              Map<String, List<String>> searchAvail) {
    // print(searchAvail);
    if (searchAvail.isEmpty) return true; // if availability is not specified, do not bother
    List<String> searchAvailKeys = searchAvail.keys.toList();
    bool areSame = false;
    searchAvailKeys.forEach((key) {
      if (myuserAvail.containsKey(key)) {
        searchAvail[key].forEach((val) {
          areSame = areSame || myuserAvail[key].containsKey(val.toLowerCase());
        });
      }
    });
    return areSame;
  }

  /// check if the location of a prospective myuser is within the select distance range
  bool _isWithinDistance(double lat1, double long1, double lat2, double long2, double acceptableRange) {
    final double dist = Distance().as(LengthUnit.Mile,
          new LatLng(lat1, long1), new LatLng(lat2, long2));
    return dist <= acceptableRange;
  }

  /// go through document snapshots from database
  List<Widget> _buildMyuserItems(List<DocumentSnapshot> docs) {
    /// filter through documents and remove what doesn't match availability and distance range
    List<String> toRemove = [];
    docs.forEach((d) {
      if (d.data['coordinates'] != null && ResultsState.currCoordinates != null) {
        List<String> myuserCoordinates = (d.data['coordinates']).split(",");
        List<String> currCoordinates = ResultsState.currCoordinates.split(",");

        // check distance
        if(!_isWithinDistance(
          double.parse(myuserCoordinates[0]), 
          double.parse(myuserCoordinates[1]), 
          double.parse(currCoordinates[0]), 
          double.parse(currCoordinates[1]), 
          CriteriaState.distSliderVal)) toRemove.add(d.documentID);
      }
      
      if (d.data['availability'] != null && ResultsState.availability != null) {
        // check availability
        if(!_areAvailabilitiesSame(
          Map<String, dynamic>.from(d.data['availability']), 
          ResultsState.availability)) toRemove.add(d.documentID);
        }
    });

    // remove what doesn't match. We feed the unwanted to an external list to prevent
    // the error of trying to remove while iterating
    docs.removeWhere((d) => toRemove.contains(d.documentID));

    List<Widget> _myuserList = new List<Widget>();
    // Map the prospective myuser(s) to a MyuserItem to be fed into the ListView
    _myuserList = docs.map((document) {
      return MyuserItem(
        myuser: Myuser.fromMap(document.data, document.documentID),
        id: widget.id,
        auth: widget.auth,
        chats: widget.chats,
      ); 
    }).toList();

    // return list if there are result. Otherwise, show 'No results found'
    return _myuserList.length > 0 ? _myuserList : 
      [Container(margin: EdgeInsets.only(top: 60.0), child: Center(child: Text("No results found"),))];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Myusers"), backgroundColor: Colors.orange,),
      body: Container(
        margin: EdgeInsets.only(top: 20.0),
        child: widget.access != null && widget.access.query != null ? StreamBuilder(
          stream: widget.access.query.snapshots(),
          builder: (BuildContext context, 
              AsyncSnapshot<QuerySnapshot> snapshot) {
            return snapshot.hasData ? ListView(
              children: _buildMyuserItems(snapshot.data.documents)
            ) : Center(child: Text("No Myusers found."),);
          }
        ) : Center(child: Text("Click on the Search tab.")),
      ),
    );
  }
}