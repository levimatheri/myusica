import 'package:flutter/material.dart';
import 'package:myusica/helpers/specializations.dart';

class SpecializationQuery extends StatefulWidget {
  final List<String> selected;
  SpecializationQuery(List<String> selected) 
      : selected = selected;
  SpecializationQueryState createState() => SpecializationQueryState();
}

class SpecializationQueryState extends State<SpecializationQuery> {
  // @override
  // void initState() {
  //   super.initState();
  //   // hacky way of ensuring checkboxes are selected when returning to this screen
  //   if (widget.selected != null) {
  //     widget.selected.forEach((item) {
  //       timePickers[item].checked = true;
  //     });
  //   }
  // }

  _buildCheckboxList() {
    return ListView.builder(
      itemCount: specialization_list.length,
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
          // if user had already selected items before, show them as selected
          value: widget.selected != null && widget.selected.length != 0 ?
            widget.selected.contains(specialization_list[index]) : false,
          title: Text(specialization_list[index]),
          onChanged: (val) {
            setState(() {
              // if checked, add item to selected items else remove the item
              if (val) widget.selected.add(specialization_list[index]);
              else widget.selected.remove(specialization_list[index]);
            });
          },
        );
      },
    );
  }

  // _addItem() {
  //   return AlertDialog(
  //     content: SingleChildScrollView(
  //       child: ListBody(
  //         children: <Widget>[
  //           Container(
  //             margin: const EdgeInsets.only(bottom: 20.0),
  //           ),
  //           TextField(
  //             decoration: InputDecoration(
  //               hintText: "Enter new specialization"
  //             ),
  //           ),
  //           RaisedButton(
  //             child: Text("Add"),
  //             onPressed: null,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add specializations'),
        // actions: <Widget>[
        //   IconButton(icon: Icon(Icons.add), onPressed: _addItem,)
        // ],
      ),
      body: Container(
        child: _buildCheckboxList(),
      ),
    );
  }
}