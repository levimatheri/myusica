import 'package:flutter/material.dart';

class AvailabilityItem extends StatefulWidget {
  final int position;
  final List<Widget> checkboxes;
  AvailabilityItem(int position, List<Widget> checkboxes)
                  : position = position, checkboxes = checkboxes;

  _AvailabilityItemState createState() => _AvailabilityItemState(position, checkboxes);
}

class _AvailabilityItemState extends State<AvailabilityItem> {
  var _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  int position;
  List<Widget> checkboxes;

  _AvailabilityItemState(int position, List<Widget> checkboxes) {
    this.position = position;
    this.checkboxes = checkboxes;
  }

  @override
    Widget build(BuildContext context) {
      return ListTile(
        leading: Text(_days[position]),
        title: Row(
          children: checkboxes,
        ),
      );
    }
}