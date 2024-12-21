import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:weatherapp/addditional_info.dart';
import 'package:weatherapp/hourlyforcast.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String selectedCity = 'Mumbai';
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  bool isDarkMode = false;

  final List<String> popularCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Kolkata',
    'Hyderabad',
  ];

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://api.openweathermap.org/data/2.5/forecast?q=$selectedCity,IN&APPID=537c6f63b8812c8cf0a12e322e0188cf',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        throw 'An unexpected error occurred';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final response = await http.get(
        Uri.parse(
          'http://api.openweathermap.org/geo/1.0/reverse?lat=${position.latitude}&lon=${position.longitude}&limit=1&appid=537c6f63b8812c8cf0a12e322e0188cf',
        ),
      );
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        setState(() {
          selectedCity = data[0]['name'];
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

@override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    Colors.blueGrey.shade900,
                    Colors.blueGrey.shade700,
                  ]
                : [
                    Colors.blue.shade400,
                    Colors.blue.shade100,
                  ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPopularCitiesSection(),
                    SizedBox(height: size.height * 0.03),
                    _buildWeatherContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade500,
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
        title: isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        selectedCity = _searchController.text;
                        isSearching = false;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
              )
            : Text(selectedCity),
      ),
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              isSearching = !isSearching;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: _getCurrentLocation,
        ),
      ],
    );
  }

  Widget _buildPopularCitiesSection() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: popularCities.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(popularCities[index]),
              selected: selectedCity == popularCities[index],
              selectedColor: Colors.blue.shade100,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedCity = popularCities[index];
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherContent() {
    return FutureBuilder(
      future: getCurrentWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final data = snapshot.data!;
        final currentTemp = data['list'][0]['main']['temp'];
        final currentSky = data['list'][0]['weather'][0]['main'];
        final currentPressure = data['list'][0]['main']['pressure'];
        final currentWindSpeed = data['list'][0]['wind']['speed'];
        final currentHumidity = data['list'][0]['main']['humidity'];
        final currentVisibility = data['list'][0]['visibility'] / 1000; // Convert to km

        return Column(
          children: [
            _buildMainWeatherCard(currentTemp, currentSky, currentHumidity, isDarkMode),
            const SizedBox(height: 20),
            _buildHourlyForecastSection(data),
            const SizedBox(height: 20),
            _buildAdditionalInfoGrid(
              currentHumidity,
              currentWindSpeed,
              currentPressure,
              currentVisibility,
              isDarkMode,
            ),
          ],
        );
      },
    );
  }

Widget _buildMainWeatherCard(
    dynamic temp,
    String sky,
    dynamic humidity,
    bool isDarkMode,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Card(
          elevation: 10,
          shadowColor: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.blue.shade900.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: isDarkMode
              ? Colors.blueGrey.shade800.withOpacity(0.7)
              : Colors.white.withOpacity(0.9),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 20,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildHumidityBadge(humidity, isDarkMode, isSmallScreen),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),
                _buildTemperatureRow(temp, sky, isDarkMode, isSmallScreen),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHourlyForecastSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hourly Forecast',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              final hourlyForecast = data['list'][index + 1];
              final time = DateTime.parse(hourlyForecast['dt_txt']);
              final temp = hourlyForecast['main']['temp'];
              final weather = hourlyForecast['weather'][0]['main'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: HourlyForecast(
                  icon: weather == 'Clouds' || weather == 'Rain'
                      ? Icons.cloud
                      : Icons.wb_sunny_rounded,
                  label: DateFormat('ha').format(time),
                  value: '${(temp - 273.15).toStringAsFixed(1)}°C',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
   Widget _buildHumidityBadge(
    dynamic humidity,
    bool isDarkMode,
    bool isSmallScreen,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blueGrey.shade700
            : Colors.blue.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop,
            size: isSmallScreen ? 16 : 20,
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            '$humidity%',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: isDarkMode ? Colors.white : Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoGrid(
    dynamic humidity,
    dynamic windSpeed,
    dynamic pressure,
    dynamic visibility,
    bool isDarkMode,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 2 : 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isSmallScreen ? 1.3 : 1.5,
          children: [
            _buildInfoCard(
              Icons.water_drop,
              "Humidity",
              "$humidity%",
              Colors.blue.shade300,
              isDarkMode,
            ),
            _buildInfoCard(
              Icons.air,
              "Wind Speed",
              "$windSpeed m/s",
              Colors.green.shade300,
              isDarkMode,
            ),
            _buildInfoCard(
              Icons.compress,
              "Pressure",
              "$pressure hPa",
              Colors.orange.shade300,
              isDarkMode,
            ),
            _buildInfoCard(
              Icons.visibility,
              "Visibility",
              "${visibility.toStringAsFixed(1)} km",
              Colors.purple.shade300,
              isDarkMode,
            ),
          ],
        );
      },
    );
  }
 Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: isDarkMode
          ? Colors.blueGrey.shade800.withOpacity(0.7)
          : Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 Widget _buildTemperatureRow(
    dynamic temp,
    String sky,
    bool isDarkMode,
    bool isSmallScreen,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(temp - 273.15).toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: isSmallScreen ? 48 : 64,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.blue.shade900,
                ),
              ),
              Text(
                sky,
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
        Icon(
          sky == 'Clouds' || sky == 'Rain'
              ? Icons.cloud
              : Icons.wb_sunny_rounded,
          size: isSmallScreen ? 64 : 80,
          color: sky == 'Clouds' || sky == 'Rain'
              ? Colors.blue.shade300
              : Colors.orange.shade400,
        ),
      ],
    );
  }
