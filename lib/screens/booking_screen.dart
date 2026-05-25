import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {

  String selectedSlot = "";

  final ApiService apiService = ApiService();

  final List<String> slots = [
    "10:00 AM",
    "11:00 AM",
    "12:00 PM"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Book Slot")),
      body: Center(
        child: DropdownButton<String>(
          value: selectedSlot.isEmpty ? null : selectedSlot,
          hint: Text("Select Slot"),
          items: slots.map((slot) {
            return DropdownMenuItem(
              value: slot,
              child: Text(slot),
            );
          }).toList(),
          onChanged: (value) async {

            if (value == null) return;

            setState(() {
              selectedSlot = value;
            });

            try {

              await apiService.updateSlot(
                slotId: 1,
                newTime: value,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Slot Updated")),
              );

            } catch (e) {

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Update Failed")),
              );
            }
          },
        ),
      ),
    );
  }
}
