import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = DateFormat('d').format(now);
    final monthYear = DateFormat('MMMM yyyy', 'es').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              monthYear,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Table(
              children: [
                TableRow(
                  children: ['D', 'L', 'M', 'M', 'J', 'V', 'S']
                      .map((d) => Center(child: Text(d)))
                      .toList(),
                ),
                for (int i = 0; i < 5; i++)
                  TableRow(
                    children: List.generate(7, (j) {
                      final dayNum = i * 7 + j + 1;
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (dayNum == int.parse(day)) ? Colors.blue : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: (dayNum == int.parse(day)) ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _eventItem('14:00', 'Rediseño web', Colors.blue),
            _eventItem('', 'Factura #1502', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _eventItem(String time, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 12),
          Text.rich(
            TextSpan(
              text: time.isNotEmpty ? '$time  ' : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}