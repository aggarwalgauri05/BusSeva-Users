// search_results_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'bus_detail_page.dart';

class SearchResultsPage extends StatelessWidget {
  final String from;
  final String to;
  final DateTime date;
  final TimeOfDay time;

  const SearchResultsPage({
    Key? key,
    required this.from,
    required this.to,
    required this.date,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for bus results
    final List<Map<String, dynamic>> busResults = [
      {
        'busName': 'Red Bus',
        'busNumber': 'B-1234',
        'route': 'Via City Center, Main Station',
        'fare': 150,
        'duration': 45,
        'rating': 4.5,
        'reviews': 210,
        'occupancy': '🟢 Available',
        'eta': 12,
      },
      {
        'busName': 'Green Bus',
        'busNumber': 'B-5678',
        'route': 'Via Mall, University',
        'fare': 120,
        'duration': 50,
        'rating': 4.2,
        'reviews': 142,
        'occupancy': '🟡 Filling',
        'eta': 15,
      },
      {
        'busName': 'Blue Bus',
        'busNumber': 'B-9101',
        'route': 'Via Old Town, Market',
        'fare': 180,
        'duration': 40,
        'rating': 4.8,
        'reviews': 350,
        'occupancy': '🔴 Full',
        'eta': 8,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '$from → $to',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement edit search functionality
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersBar(context),
          Expanded(
            child: busResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: busResults.length,
                    itemBuilder: (context, index) {
                      final bus = busResults[index];
                      return _buildBusCard(context, bus);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('AC', const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _buildFilterChip('Non-AC', Colors.grey),
            const SizedBox(width: 8),
            _buildFilterChip('Sort by: Fare', const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _buildFilterChip('Occupancy', const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, Map<String, dynamic> bus) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusDetailPage(busData: bus),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bus['busName'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getOccupancyColor(bus['occupancy']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bus['occupancy'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getOccupancyColor(bus['occupancy']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bus['route'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(CupertinoIcons.ticket, size: 16, color: Color(0xFF667EEA)),
                const SizedBox(width: 4),
                Text(
                  '₹${bus['fare']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  '${bus['duration']} min',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${bus['rating']} (${bus['reviews']})',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Arrives in ${bus['eta']} min',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement live tracking
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF667EEA),
                      side: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Track Live', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusDetailPage(busData: bus),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getOccupancyColor(String occupancy) {
    if (occupancy.contains('Available')) {
      return const Color(0xFF10B981);
    } else if (occupancy.contains('Filling')) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bus_alert, size: 80, color: Color(0xFF6B7280)),
          SizedBox(height: 20),
          Text(
            'No buses found.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or time.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}