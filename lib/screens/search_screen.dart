// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/bus_search_service.dart';
import '../models/route_model.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BusSearchService _searchService = BusSearchService();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  List<RouteSearchResult> _searchResults = [];
  List<BusRoute> _popularRoutes = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  // Filter controllers
  final TextEditingController _maxFareController = TextEditingController();
  final TextEditingController _maxDurationController = TextEditingController();
  final TextEditingController _departureAfterController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadPopularRoutes();
  }
  
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _maxFareController.dispose();
    _maxDurationController.dispose();
    _departureAfterController.dispose();
    super.dispose();
  }
  
  void _loadPopularRoutes() async {
    try {
      List<BusRoute> routes = await _searchService.getPopularRoutes();
      setState(() {
        _popularRoutes = routes;
      });
    } catch (e) {
      print('Error loading popular routes: $e');
    }
  }
  
  void _searchRoutes() async {
    if (_fromController.text.trim().isEmpty || _toController.text.trim().isEmpty) {
      _showSnackBar('Please select both origin and destination cities');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      List<RouteSearchResult> results = await _searchService.searchRoutes(
        fromCity: _fromController.text,
        toCity: _toController.text,
        maxFare: _maxFareController.text.isNotEmpty ? int.tryParse(_maxFareController.text) : null,
        maxDuration: _maxDurationController.text.isNotEmpty ? _maxDurationController.text : null,
        departureAfter: _departureAfterController.text.isNotEmpty ? _departureAfterController.text : null,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      
      if (results.isEmpty) {
        _showSnackBar('No routes found for the selected cities');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to search routes. Please try again.');
      print('Search error: $e');
    }
  }
  
  void _swapCities() {
    String temp = _fromController.text;
    setState(() {
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }
  
  void _clearFilters() {
    setState(() {
      _maxFareController.clear();
      _maxDurationController.clear();
      _departureAfterController.clear();
    });
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_bus, color: Colors.white),
            SizedBox(width: 8),
            Text('BusSeva', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Form
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your Bus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // From and To inputs
                  Row(
                    children: [
                      Expanded(
                        child: _buildCityInput(
                          controller: _fromController,
                          label: 'From',
                          icon: Icons.radio_button_checked,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            SizedBox(height: 20), // Align with input fields
                            InkWell(
                              onTap: _swapCities,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: Colors.blue[600],
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildCityInput(
                          controller: _toController,
                          label: 'To',
                          icon: Icons.location_on,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Date picker
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                          SizedBox(width: 12),
                          Text(
                            _formatDate(_selectedDate),
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Filter toggle and search button
                  // This is the corrected code

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    TextButton.icon(
      onPressed: () {
        setState(() {
          _showFilters = !_showFilters;
        });
      },
      icon: Icon(Icons.tune),
      label: Text('Filters'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue[600],
      ),
    ),
    Flexible( // Add this widget
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _searchRoutes,
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.search),
        label: Text(_isLoading ? 'Searching...' : 'Search Buses'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ), // And close it here
  ],
),
                  
                  // Filters section
                  if (_showFilters) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: _clearFilters,
                                child: Text('Clear All'),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _buildFilterInput(
                            controller: _maxFareController,
                            label: 'Max Fare (₹)',
                            hint: 'e.g., 500',
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 12),
                          _buildFilterInput(
                            controller: _maxDurationController,
                            label: 'Max Duration',
                            hint: 'e.g., 6h 30m',
                          ),
                          SizedBox(height: 12),
                          _buildFilterInput(
                            controller: _departureAfterController,
                            label: 'Departure After',
                            hint: 'HH:MM (24-hour format)',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Search Results
            if (_searchResults.isNotEmpty)
              _buildSearchResults()
            else if (!_isLoading && _searchResults.isEmpty && _fromController.text.isEmpty)
              _buildPopularRoutes(),
              
            if (_isLoading)
              Container(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Finding the best routes for you...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
            // No results message
            if (!_isLoading && _searchResults.isEmpty && _fromController.text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No routes found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try different cities or check your spelling',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCityInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 20),
            hintText: 'Select city',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onTap: () => _showCityPicker(controller),
          readOnly: true,
        ),
      ],
    );
  }
  
  Widget _buildFilterInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
  
  void _showCityPicker(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CityPickerBottomSheet(
        onCitySelected: (city) {
          controller.text = city;
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    List<String> weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    
    String weekday = weekdays[date.weekday - 1];
    String month = months[date.month - 1];
    
    return '$weekday, ${date.day} $month ${date.year}';
  }
  
  Widget _buildSearchResults() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${_searchResults.length} route${_searchResults.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchResults.clear();
                    });
                  },
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Clear'),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return RouteCard(result: _searchResults[index]);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopularRoutes() {
    if (_popularRoutes.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No popular routes available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Routes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _popularRoutes.length,
            itemBuilder: (context, index) {
              BusRoute route = _popularRoutes[index];
              String fromCity = route.stops.isNotEmpty ? route.stops.first.city : '';
              String toCity = route.stops.isNotEmpty ? route.stops.last.city : '';
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _fromController.text = fromCity;
                    _toController.text = toCity;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$fromCity → $toCity',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        route.estimatedDuration,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Route Card Widget
class RouteCard extends StatelessWidget {
  final RouteSearchResult result;
  
  const RouteCard({Key? key, required this.result}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.route.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: result.activeBuses > 0 ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${result.activeBuses} bus${result.activeBuses != 1 ? 'es' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: result.activeBuses > 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Route details
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${result.fromStop.name} → ${result.toStop.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Time and fare row
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.blue[600]),
              SizedBox(width: 4),
              Text(
                result.estimatedDuration,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(width: 16),
              Icon(Icons.currency_rupee, size: 16, color: Colors.green[600]),
              SizedBox(width: 4),
              Text(
                '₹${result.fare}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Spacer(),
              Text(
                '${result.distance.toStringAsFixed(0)} km',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          
          // Next bus info
          if (result.nextBus != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, size: 16, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Bus: ${result.nextBus!['busNumber']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Arrives in ${result.nextBus!['estimatedMinutes']} mins',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${result.nextBus!['occupancy']}/45 seats',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 12),
          
          // View details button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: result.activeBuses > 0 ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailsScreen(result: result),
                  ),
                );
              } : null,
              child: Text(
                result.activeBuses > 0 ? 'View Details' : 'No Buses Available',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: result.activeBuses > 0 ? Colors.blue[600] : Colors.grey[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// City Picker Bottom Sheet
class CityPickerBottomSheet extends StatefulWidget {
  final Function(String) onCitySelected;
  
  const CityPickerBottomSheet({Key? key, required this.onCitySelected}) : super(key: key);
  
  @override
  _CityPickerBottomSheetState createState() => _CityPickerBottomSheetState();
}

class _CityPickerBottomSheetState extends State<CityPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final BusSearchService _searchService = BusSearchService();
  List<String> _cities = [];
  List<String> _filteredCities = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCities();
    _searchController.addListener(_filterCities);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadCities() async {
    try {
      List<String> cities = await _searchService.searchCities('');
      setState(() {
        _cities = cities;
        _filteredCities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading cities: $e');
    }
  }
  
  void _filterCities() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _cities
          .where((city) => city.toLowerCase().contains(query))
          .toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Select City',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search cities...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Cities list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredCities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_city,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No cities found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          String city = _filteredCities[index];
                          return ListTile(
                            leading: Icon(Icons.location_city, color: Colors.grey[600]),
                            title: Text(city),
                            onTap: () => widget.onCitySelected(city),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Route Details Screen
class RouteDetailsScreen extends StatelessWidget {
  final RouteSearchResult result;
  
  const RouteDetailsScreen({Key? key, required this.result}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.route.name),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route summary card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journey Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSummaryRow(Icons.location_on, 'From', result.fromStop.name),
                  _buildSummaryRow(Icons.flag, 'To', result.toStop.name),
                  _buildSummaryRow(Icons.access_time, 'Duration', result.estimatedDuration),
                  _buildSummaryRow(Icons.straighten, 'Distance', '${result.distance.toStringAsFixed(0)} km'),
                  _buildSummaryRow(Icons.currency_rupee, 'Fare', '₹${result.fare}'),
                  _buildSummaryRow(Icons.directions_bus, 'Active Buses', '${result.activeBuses}'),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Next bus info
            if (result.nextBus != null) ...[
              Text(
                'Next Bus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: Colors.blue[600]),
                        SizedBox(width: 8),
                        Text(
                          result.nextBus!['busNumber'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${result.nextBus!['occupancy']}/45 seats',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Driver: ${result.nextBus!['driver']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Arrives in: ${result.nextBus!['estimatedMinutes']} minutes',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
            
            // All stops
            Text(
              'All Stops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: result.route.stops.asMap().entries.map((entry) {
                  int index = entry.key;
                  RouteStop stop = entry.value;
                  bool isFromStop = stop.id == result.fromStop.id;
                  bool isToStop = stop.id == result.toStop.id;
                  bool isBetween = stop.stopOrder > result.fromStop.stopOrder && 
                                   stop.stopOrder < result.toStop.stopOrder;
                  bool isLast = index == result.route.stops.length - 1;
                  
                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: (isFromStop || isToStop) ? Colors.blue[50] : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isFromStop ? Colors.green : 
                                           isToStop ? Colors.red : 
                                           isBetween ? Colors.blue : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 20,
                                    color: Colors.grey[300],
                                  ),
                              ],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: (isFromStop || isToStop) ? Colors.blue[800] : null,
                                    ),
                                  ),
                                  Text(
                                    stop.city,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (stop.departureTime != null || stop.arrivalTime != null)
                                    Text(
                                      '${stop.arrivalTime ?? ''} ${stop.departureTime != null ? '- ${stop.departureTime}' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${stop.distanceFromStart.toStringAsFixed(0)} km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Book now button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: result.activeBuses > 0 ? () {
                  _showBookingDialog(context);
                } : null,
                child: Text(
                  result.activeBuses > 0 ? 'Book Now - ₹${result.fare}' : 'No Buses Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: result.activeBuses > 0 ? Colors.green[600] : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Coming Soon!'),
          ],
        ),
        content: Text(
          'Seat booking and payment functionality will be available in the next update. Stay tuned!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // You can add notification sign-up functionality here
            },
            child: Text('Notify Me'),
          ),
        ],
      ),
    );
  }
}