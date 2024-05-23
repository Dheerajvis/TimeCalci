import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TimeCalculator(),
    );
  }
}

class TimeCalculator extends StatefulWidget {
  const TimeCalculator({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TimeCalculatorState createState() => _TimeCalculatorState();
}

class _TimeCalculatorState extends State<TimeCalculator> {
  TimeOfDay startTime = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 30);
  Duration customDuration = const Duration(hours: 0, minutes: 0);
  String result = '';
  final List<Map<String, String>> history = [];
  final TextEditingController durationHoursController = TextEditingController();
  final TextEditingController durationMinutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedValues();
  }

  void _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      durationHoursController.text = (prefs.getInt('duration_hours') ?? 0).toString();
      durationMinutesController.text = (prefs.getInt('duration_minutes') ?? 0).toString();
      customDuration = Duration(
        hours: prefs.getInt('duration_hours') ?? 0,
        minutes: prefs.getInt('duration_minutes') ?? 0,
      );
      final encodedHistory = prefs.getStringList('history');
      if (encodedHistory != null) {
        history.addAll(encodedHistory.map((entry) {
          final parts = entry.split('|');
          return {'date': parts[0], 'entry': parts[1]};
        }).toList());
      }
    });
  }

  void _saveValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'duration_hours', int.tryParse(durationHoursController.text) ?? 0);
    await prefs.setInt(
        'duration_minutes', int.tryParse(durationMinutesController.text) ?? 0);
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedHistory = history.map((entry) => '${entry['date']}|${entry['entry']}').toList();
    await prefs.setStringList('history', encodedHistory);
  }

  void getCurrentTime() {
    final now = TimeOfDay.now();
    setState(() {
      endTime = now;
    });
  }

  void addToHistory(String entry) {
    final now = DateTime.now();
    final formattedDate = DateFormat.yMMMd().format(now);
    setState(() {
      history.add({'date': formattedDate, 'entry': entry});
    });
    _saveHistory();
  }

  void calculateEndTime() {
    final endDateTime = DateTime(
      2023,
      1,
      1,
      startTime.hour + customDuration.inHours,
      startTime.minute + customDuration.inMinutes.remainder(60),
    );
    final formattedTime = DateFormat.jm().format(endDateTime);
    final entry = 'End Time: $formattedTime';
    addToHistory(entry);
    setState(() {
      result = entry;
    });
  }

  // void calculateStartTime() {
  //   final startDateTime = DateTime(
  //     2023,
  //     1,
  //     1,
  //     endTime.hour - customDuration.inHours,
  //     endTime.minute - customDuration.inMinutes.remainder(60),
  //   );
  //   final formattedTime = DateFormat.jm().format(startDateTime);
  //   final entry = 'Start Time: $formattedTime';
  //   addToHistory(entry);
  //   setState(() {
  //     result = entry;
  //   });
  // }

  void calculateDuration() {
    final durationHours = endTime.hour - startTime.hour;
    final durationMinutes = endTime.minute - startTime.minute;
    final adjustedDurationMinutes = durationMinutes < 0 ? durationMinutes + 60 : durationMinutes;
    final adjustedDurationHours = durationMinutes < 0 ? durationHours - 1 : durationHours;
    final entry = 'Duration: $adjustedDurationHours hours $adjustedDurationMinutes minutes';
    addToHistory(entry);
    setState(() {
      result = entry;
    });
  }

  void resetValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('duration_hours');
    await prefs.remove('duration_minutes');
    await prefs.remove('history');

    setState(() {
      startTime = const TimeOfDay(hour: 11, minute: 0);
      endTime = const TimeOfDay(hour: 19, minute: 30);
      //customDuration = const Duration(hours: 0, minutes: 0);
      result = '';
      //durationHoursController.clear();
      //durationMinutesController.clear();
      //history.clear();
    });
  }

  Future<void> selectTime(BuildContext context, bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    durationHoursController.dispose();
    durationMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryPage(
                    history: history,
                    clearHistory: () {
                      setState(() {
                        history.clear();
                      });
                      _saveHistory();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text('Start Time:'),
                    ElevatedButton(
                      onPressed: () => selectTime(context, true),
                      child: Text(startTime.format(context)),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('End Time:'),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => selectTime(context, false),
                          child: Text(endTime.format(context)),
                        ),
                        TextButton(
                          onPressed: getCurrentTime,
                          child: const Text('Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: durationHoursController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Hours',
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            customDuration = Duration(
                              hours: int.tryParse(value) ?? 0,
                              minutes: customDuration.inMinutes.remainder(60),
                            );
                          });
                          _saveValues();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: durationMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Minutes',
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            customDuration = Duration(
                              hours: customDuration.inHours,
                              minutes: int.tryParse(value) ?? 0,
                            );
                          });
                          _saveValues();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: calculateEndTime,
                  child: const Text('End Time'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: calculateDuration,
                  child: const Text('Duration'),
                ),
                // ElevatedButton(
                //   onPressed: calculateStartTime,
                //   child: const Text('Start Time'),
                // )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: resetValues,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              result,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

