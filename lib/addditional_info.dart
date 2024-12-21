import 'package:flutter/material.dart';
class AdditionalInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? customColor;

  const AdditionalInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? Theme.of(context).primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
// Example of how to use AdditionalInfoItem with different colors
class WeatherInfoGrid extends StatelessWidget {
  const WeatherInfoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      children: [
        AdditionalInfoItem(
          icon: Icons.water_drop,
          label: "Humidity",
          value: "65%",
          customColor: Colors.blue,
        ),
        AdditionalInfoItem(
          icon: Icons.air,
          label: "Wind Speed",
          value: "5.3 m/s",
          customColor: Colors.green,
        ),
        AdditionalInfoItem(
          icon: Icons.compress,
          label: "Pressure",
          value: "1014 hPa",
          customColor: Colors.orange,
        ),
        AdditionalInfoItem(
          icon: Icons.visibility,
          label: "Visibility",
          value: "10 km",
          customColor: Colors.purple,
        ),
        
      ],
    );
  }
}