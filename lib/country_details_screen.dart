import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For using NetworkImage for Flag
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Map plugin

class CountryDetailsScreen extends StatefulWidget {
  final String countryName;

  const CountryDetailsScreen({required this.countryName, Key? key}) : super(key: key);

  @override
  _CountryDetailsScreenState createState() => _CountryDetailsScreenState();
}

class _CountryDetailsScreenState extends State<CountryDetailsScreen> {
  late Future<Map<String, dynamic>> _countryDetails;
  late Future<Map<String, dynamic>> _weatherDetails;
  late LatLng _countryLatLng;

  @override
  void initState() {
    super.initState();
    _countryDetails = _fetchCountryDetails(widget.countryName);
    _weatherDetails = _fetchWeatherDetails(widget.countryName);
  }

  Future<Map<String, dynamic>> _fetchCountryDetails(String countryName) async {
    final response = await http.get(Uri.parse('https://restcountries.com/v3.1/name/$countryName'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        // Set coordinates for the map
        _countryLatLng = LatLng(data[0]['latlng'][0], data[0]['latlng'][1]);
      }
      return data.isNotEmpty ? data[0] : {};
    } else {
      throw Exception('Failed to load country details');
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherDetails(String countryName) async {
    final response = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=${countryName}&appid=649ebb284afab8e0d8a80a64fb8095ba&units=metric'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.countryName),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _countryDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _buildCountryDetails(snapshot.data!);
          } else {
            return const Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }

  Widget _buildCountryDetails(Map<String, dynamic> details) {
    final capital = details['capital']?[0] ?? 'N/A';
    final population = details['population'] ?? 'N/A';
    final region = details['region'] ?? 'N/A';
    final subregion = details['subregion'] ?? 'N/A';
    final location = details['latlng'] != null
        ? '${details['latlng'][0]}, ${details['latlng'][1]}'
        : 'N/A';
    final languages = details['languages'] != null
        ? (details['languages'] as Map).values.join(', ')
        : 'N/A';
    final flagUrl = details['flags']?['png'] ?? '';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Country: ${widget.countryName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFlag(flagUrl),
            const SizedBox(height: 20),
            _detailRow('Capital:', capital),
            _detailRow('Population:', population.toString()),
            _detailRow('Region:', region),
            _detailRow('Subregion:', subregion),
            _detailRow('Location (Lat, Long):', location),
            _detailRow('Languages Spoken:', languages),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: _weatherDetails,
              builder: (context, weatherSnapshot) {
                if (weatherSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (weatherSnapshot.hasError) {
                  return Center(child: Text('Error: ${weatherSnapshot.error}'));
                } else if (weatherSnapshot.hasData) {
                  return _buildWeatherDetails(weatherSnapshot.data!);
                } else {
                  return const Center(child: Text('No weather data found.'));
                }
              },
            ),
            const SizedBox(height: 20),
            _buildMap(),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlag(String flagUrl) {
    return flagUrl.isNotEmpty
        ? Image.network(flagUrl, height: 100)
        : const Icon(Icons.flag, size: 100);
  }

  Widget _buildMap() {
    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _countryLatLng,
          zoom: 6,
        ),
        markers: {
          Marker(
            markerId: MarkerId(widget.countryName),
            position: _countryLatLng,
          ),
        },
      ),
    );
  }

  Widget _buildWeatherDetails(Map<String, dynamic> weatherDetails) {
    final temperature = weatherDetails['main']?['temp']?.toString() ?? 'N/A';
    final weatherCondition = weatherDetails['weather']?[0]['description'] ?? 'N/A';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather in ${widget.countryName} (Capital):',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        _detailRow('Temperature:', '$temperature°C'),
        _detailRow('Weather Condition:', weatherCondition),
      ],
    );
  }
}
