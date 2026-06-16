// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../widgets/app_loading_indicator.dart';
import '../services/api_service.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService apiService = ApiService();
  
  List<Map<String, dynamic>> _slots = [];
  Map<String, dynamic>? _selectedSlot;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fetched = await apiService.fetchSlots();
      setState(() {
        _slots = fetched;
        _isLoading = false;
        // Keep selected slot synced if still in list
        if (_selectedSlot != null) {
          _selectedSlot = _slots.firstWhere(
            (s) => s['id'] == _selectedSlot!['id'],
            orElse: () => _slots.first,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load slots: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _bookSlot() async {
    if (_selectedSlot == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final slotId = _selectedSlot!['id'] as int;
      final slotTime = _selectedSlot!['time'] as String;

      await apiService.updateSlot(
        slotId: slotId,
        newTime: slotTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Slot Booked/Updated Successfully!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to book slot: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Dynamic Slot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSlots,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Choose an Available Court/Slot",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedSlot,
                        hint: const Text("Select Slot"),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        ),
                        items: _slots.map((slot) {
                          final time = slot['time'] as String;
                          final status = slot['status'] as String;
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: slot,
                            child: Text("$time ($status)"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSlot = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _selectedSlot == null || _isUpdating
                              ? null
                              : _bookSlot,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                          child: _isUpdating
                              ? const AppLoadingIndicator()
                              : const Text(
                                  "Confirm Booking",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
