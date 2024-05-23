import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, String>> history;
  final Function clearHistory;

  const HistoryPage({super.key, required this.history, required this.clearHistory});

  Map<String, List<String>> _groupByDate() {
    final Map<String, List<String>> groupedHistory = {};
    for (var entry in history) {
      final date = entry['date']!;
      final historyEntry = entry['entry']!;
      if (groupedHistory.containsKey(date)) {
        groupedHistory[date]!.add(historyEntry);
      } else {
        groupedHistory[date] = [historyEntry];
      }
    }
    return groupedHistory;
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = _groupByDate();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        titleSpacing: 0.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Are you sure you want to clear the history?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearHistory();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: groupedHistory.keys.length,
        itemBuilder: (context, index) {
          final date = groupedHistory.keys.elementAt(index);
          final entries = groupedHistory[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  date,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ...entries.map((entry) => ListTile(
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4.0),
                title: Text(entry),
              )),
            ],
          );
        },
      ),
    );
  }
}
