import 'package:flutter/material.dart';

class AvailabilityQuery extends StatefulWidget {
  AvailabilityQueryState createState() => AvailabilityQueryState();
}

class AvailabilityQueryState extends State<AvailabilityQuery> {
  Map _slots = Map<String, List<String>>();
  var _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  var _times = ['Morning', 'Afternoon', 'Evening'];
  List<TimePicker> timePickers;

  AvailabilityQueryState() {
    // x ~/ y is same as  (x / y).toInt()

    /// generate checkboxes
    timePickers = List<TimePicker>.generate(21, (i) =>  new TimePicker(this, _days[i ~/ 3], _times[i % 3]));
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Availability'),
        ),
        body: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 30.0, left: 15.0),
              child: Text(
                'Select preferable availability times for your prospective Myuser',
                style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20.0, left: 15.0),
              child: Table(
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: Text('Day', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TableCell(
                        child: Text('Morning', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TableCell(
                        child: Text('Afternoon', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TableCell(
                        child: Text('Evening', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ], 
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            children: _buildDaysList(),
                          ), 
                        ),
                      ),
                      TableCell(
                        child: Column(
                          children: _buildAvailabilityList(0),
                        ),                              
                      ),
                      TableCell(
                        child: Column(
                          children: _buildAvailabilityList(1),
                        ),                              
                      ),
                      TableCell(
                        child: Column(
                          children: _buildAvailabilityList(2),
                        ),                              
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              child: RaisedButton(
                child: Text('Done'),
                onPressed: () {
                  Navigator.pop(context, _slots);
                }
              ),
            )
          ],
        ),
      );
    }

  /// Build the checkboxes for user selection given [index] of day in [_days] list
  List<TimePicker> _buildAvailabilityList(int index) {
    List<TimePicker> availabilityItemList = List<TimePicker>(7);
    for (int i = 0, j = index; i < 7; j += 3, i++) {
      availabilityItemList[i] = timePickers[j];
    }
    return availabilityItemList;
  }

  /// Build day title from [_days] list
  List<Container> _buildDaysList() {
    List<Container> daysList = List<Container>(7);
    for (int d = 0; d < _days.length; d++) {
      daysList[d] =  Container(
                          margin: const EdgeInsets.only(bottom: 30.0),
                          child: Text(_days[d], style: TextStyle(fontSize: 15.0)),
                        );
    }
    return daysList;
  }

  /// Sets slots Map to be returned to [Criteria] class on pop
  setSlots(bool value, String day, String time) {
    // old way
    // Map<String, bool> toSet = _slots[day];
    // toSet[time] = value;
    // _slots[day] = toSet;

    // eager memory effective way
    if (_slots[day] == null) _slots[day] = new List<String>();
    if (value) _slots[day].add(time);
    else _slots[day].remove(time);
  }
}

class TimePicker extends StatefulWidget {
  final String day;
  final String time;
  final AvailabilityQueryState aq;

  // Pass instance of [AvailabilityQueryState] to ensure we set the same _slots instance variable
  TimePicker(AvailabilityQueryState aq, String day, String time) : day = day, time = time, aq = aq;
  TimePickerState createState() => new TimePickerState(aq, day, time);
}

/// Helper class to build selection checkboxes given:
/// 1. Instance of [AvailabilityQueryState] to help with setting [_slots] Map
/// 2. Day: between Sunday to Saturday
/// 3. Time: Morning, Afternoon and Evening
class TimePickerState extends State<TimePicker> {
  String day;
  String time;
  bool checked = false;
  AvailabilityQueryState aq;
  TimePickerState(AvailabilityQueryState aq, String day, String time) {
    this.day = day;
    this.time = time;
    this.aq = aq;
  }
  @override
    Widget build(BuildContext context) {
      // return a checkbox
      return new Checkbox(value: checked, 
        onChanged: (bool value) {
          // when clicked set _slots to have the day and time selected
          setState(() {
            checked = value;    
            aq.setSlots(value, day, time);
          });
      });
    }
}