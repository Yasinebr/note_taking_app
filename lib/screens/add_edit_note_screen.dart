import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/notification_service.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _selectedReminderTime;
  String? _currentLocation;
  String? _currentWeather;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedReminderTime = widget.note!.reminderTime;
      _currentLocation = widget.note!.location;
      _currentWeather = widget.note!.weather;
      _latitude = widget.note!.latitude;
      _longitude = widget.note!.longitude;
    }
  }

  Future<void> _getCurrentLocationAndWeather() async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation = LocationService.formatLocation(position);

        // Get weather
        final weather = await WeatherService.getCurrentWeather(
          position.latitude,
          position.longitude,
        );
        _currentWeather = weather;

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location and weather updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _selectReminderTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedReminderTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedReminderTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      if (time != null) {
        setState(() {
          _selectedReminderTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final note = Note(
        id: widget.note?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        reminderTime: _selectedReminderTime,
        location: _currentLocation,
        weather: _currentWeather,
        latitude: _latitude,
        longitude: _longitude,
      );

      int noteId;
      if (widget.note == null) {
        // Adding new note
        noteId = await DatabaseService.insertNote(note);
      } else {
        // Updating existing note
        await DatabaseService.updateNote(note);
        noteId = note.id!;

        // Cancel existing notification if any
        if (widget.note!.reminderTime != null) {
          await NotificationService.cancelNotification(noteId);
        }
      }

      // Schedule notification if reminder time is set
      if (_selectedReminderTime != null) {
        await NotificationService.scheduleNotification(
          id: noteId,
          title: 'Note Reminder',
          body: _titleController.text.trim(),
          scheduledTime: _selectedReminderTime!,
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.note == null ? 'Note added' : 'Note updated'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveNote,
              child: const Text('Save', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location & Weather',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isGettingLocation ? null : _getCurrentLocationAndWeather,
                          icon: _isGettingLocation
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.location_on, size: 16),
                          label: Text(_isGettingLocation ? 'Getting...' : 'Get Location'),
                        ),
                      ],
                    ),
                    if (_currentLocation != null) ...[
                      const SizedBox(height: 8),
                      Text('📍 $_currentLocation'),
                    ],
                    if (_currentWeather != null) ...[
                      const SizedBox(height: 4),
                      Text('🌤️ $_currentWeather'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectReminderTime,
                          icon: const Icon(Icons.alarm, size: 16),
                          label: const Text('Set Reminder'),
                        ),
                      ],
                    ),
                    if (_selectedReminderTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('⏰ ${_formatDateTime(_selectedReminderTime!)}'),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedReminderTime = null;
                              });
                            },
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}