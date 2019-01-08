import 'package:flutter/material.dart';

class AvailabilityQuery extends StatefulWidget {
  AvailabilityQueryState createState() => AvailabilityQueryState();
}

class AvailabilityQueryState extends State<AvailabilityQuery> 
  with AutomaticKeepAliveClientMixin {
  Map slots = Map<String, Map<String, bool>>();
  var _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  var _times = ['Morning', 'Afternoon', 'Evening'];
  List<TimePicker> timePickers;

  AvailabilityQueryState() {
    for (var i = 0; i < _days.length; i++) {
      var newMap = { 'Morning':false, 'Afternoon':false, 'Evening':false };
      slots[_days[i]] = newMap;
    }

    // x ~/ y is same as  (x / y).toInt()
    timePickers = List<TimePicker>.generate(21, (i) =>  new TimePicker(this, _days[i ~/ 3], _times[i % 3]));
  }
  // @override
  //   void initState() {
  //     super.initState();

  //     print('Called initState()');
  //   }
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
                onPressed: () => Navigator.pop(context, slots),
              ),
            )
          ],
        ),
      );
    }

  List<TimePicker> _buildAvailabilityList(int index) {
    List<TimePicker> availabilityItemList = List<TimePicker>(7);
    for (int i = 0, j = index; i < 7; j += 3, i++) {
      availabilityItemList[i] = timePickers[j];
    }
    return availabilityItemList;
  }

  // List<Widget> _buildTimesList(String heading, int timeIndex) {
  //   List<Widget> timesList = List<Widget>(8);
  //   timesList[0] = Text(heading, style: TextStyle(fontWeight: FontWeight.bold));
  //   for (int t = 0; t < _days.length; timeIndex += 3, t++) {
  //     timesList[t+1] = timePickers[timeIndex];
  //   }
  //   return timesList;
  // }

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

  getSlots() {
    return slots;
  }

  setSlots(bool value, String day, String time) {
    Map<String, bool> toSet = slots[day];
    toSet[time] = value;
    slots[day] = toSet;
  }
  @override
    bool get wantKeepAlive => true;
}

class TimePicker extends StatefulWidget {
  final String day;
  final String time;
  final AvailabilityQueryState aq;

  // Pass instance of [AvailabilityQueryState] to ensure we set the same slots instance variable
  TimePicker(AvailabilityQueryState aq, String day, String time) : day = day, time = time, aq = aq;
  TimePickerState createState() => new TimePickerState(aq, day, time);
}

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
      return new Checkbox(value: checked, 
        onChanged: (bool value) {
          setState(() {
            checked = value;    
            aq.setSlots(value, day, time);
          });
      });
    }
}