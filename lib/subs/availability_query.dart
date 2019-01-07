import 'package:flutter/material.dart';
import 'package:myusica/helpers/availability_item.dart';

class AvailabilityQuery extends StatefulWidget {
  AvailabilityQueryState createState() => AvailabilityQueryState();
}

class AvailabilityQueryState extends State<AvailabilityQuery> {
  var slots = Map<String, Map<String, bool>>();
  var _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  List<TimePicker> timePickers;
  @override
    void initState() {
      super.initState();

      for (var i = 0; i < _days.length; i++) {
        var newMap = { 'Morning':false, 'Afternoon':false, 'Evening':false };
        slots[_days[i]] = newMap;
      }
      
      timePickers = List<TimePicker>.generate(21, (i) =>  new TimePicker());
    }
  @override
    Widget build(BuildContext context) {
      return Material(
        child: ListView(
          children: _buildAvailabilityList(),
        ),
      );
    }

  List<AvailabilityItem> _buildAvailabilityList() {
    List<AvailabilityItem> availabilityItemList = List<AvailabilityItem>(7);
    for (int i = 0, j = 0; i < 7; j += 3, i++) {
      availabilityItemList[i] = AvailabilityItem(i, timePickers.skip(j).take(3).toList());
    }
    return availabilityItemList;
  }
}

class TimePicker extends StatefulWidget {
  TimePickerState createState() => new TimePickerState();
}

class TimePickerState extends State<TimePicker> {
  bool checked = false;
  @override
    Widget build(BuildContext context) {
      return new Checkbox(value: checked, 
        onChanged: (bool value) {
          setState(() {
            checked = value;    
          });
      });
    }
}