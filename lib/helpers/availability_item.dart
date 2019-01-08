import 'package:flutter/material.dart';

class AvailabilityItem extends StatefulWidget {
  final int position;
  final List<Widget> checkboxes;
  AvailabilityItem(int position, List<Widget> checkboxes)
                  : position = position, checkboxes = checkboxes;

  _AvailabilityItemState createState() => _AvailabilityItemState(position, checkboxes);
}

class _AvailabilityItemState extends State<AvailabilityItem> {
  var _days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  int position;
  List<Widget> availabilityRow;

  _AvailabilityItemState(int position, List<Widget> availabilityRow) {
    this.position = position;
    this.availabilityRow = availabilityRow;
  }

  @override
    Widget build(BuildContext context) {
      return Row(
        children: <Widget>[
          Container(child: Text(_days[position]), margin: const EdgeInsets.only(right: 30.0)),
          Row(
            children: availabilityRow,
          ),
        ],
      );        
    }
}