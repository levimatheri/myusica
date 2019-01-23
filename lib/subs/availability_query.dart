import 'package:flutter/material.dart';

class AvailabilityQuery extends StatefulWidget {
  final List<int> selected;
  final Map<String, List<String>> _slots;
  AvailabilityQuery(List<int> selected, Map<String, List<String>> slots) 
                    : selected = selected, _slots = slots;
  AvailabilityQueryState createState() => AvailabilityQueryState();
}

class AvailabilityQueryState extends State<AvailabilityQuery> {
  var _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  var _times = ['Morning', 'Afternoon', 'Evening'];
  List<TimePicker> timePickers;

  AvailabilityQueryState() {
    // x ~/ y is same as  (x / y).toInt()

    /// generate checkboxes
    timePickers = List<TimePicker>.generate(21, (i) =>  
        new TimePicker(this, _days[i ~/ 3], _times[i % 3], i, false));
  }

  @override
    void initState() {
      // hacky way of ensuring checkboxes are selected when returning to this screen
      if (widget.selected != null) {
        widget.selected.forEach((item) {
          timePickers[item].checked = true;
        });
      }
      super.initState();
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
                if (widget._slots != null) {
                  // remove any keys without values in them from the map
                  widget._slots.keys
                      .where((k) => widget._slots[k].length == 0)
                      .toList()
                      .forEach(widget._slots.remove);
                }
                // go back to criteria screen
                Navigator.pop(context, [widget._slots, widget.selected]);
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
  setSlots(bool value, String day, String time, int position) {
    // old way
    // Map<String, bool> toSet = _slots[day];
    // toSet[time] = value;
    // _slots[day] = toSet;

    // eager memory effective way
    if (widget._slots[day] == null) widget._slots[day] = new List<String>();
    if (value) {
      widget._slots[day].add(time);
      widget.selected.add(position);
    }
    else {
      widget._slots[day].remove(time);
      widget.selected.remove(position);
    }
  }
}

class TimePicker extends StatefulWidget {
  final String day;
  final String time;
  final int position;
  final AvailabilityQueryState aq;
  bool checked;

  // Pass instance of [AvailabilityQueryState] to ensure we set the same _slots instance variable
  TimePicker(AvailabilityQueryState aq, String day, String time, int position, bool checked) 
      : day = day, time = time, aq = aq, position = position, checked = checked;
  TimePickerState createState() => new TimePickerState(aq, day, time, checked);
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
  TimePickerState(AvailabilityQueryState aq, String day, String time, bool checked) {
    this.day = day;
    this.time = time;
    this.aq = aq;
    this.checked = checked;
  }
  @override
  Widget build(BuildContext context) {
    // return a checkbox
    return new Checkbox(value: checked, 
      onChanged: (bool value) {
        // when clicked set _slots to have the day and time selected
        setState(() {
          checked = value;    
          aq.setSlots(value, day, time, widget.position);
        });
    });
  }
}