import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../models/user.dart' as app_user;
import '../models/market_price.dart';
import '../models/weather.dart';
import 'crop_suggestion_screen.dart';
import 'fertilizer_tips_screen.dart';
import 'fertilizer_recommendation_screen.dart';
import 'market_price_screen.dart';
import 'weather_screen.dart';
import 'marketplace_screen.dart';
import 'login_screen.dart';
import 'disease_detection_screen.dart';
import 'soil_based_recommendation_screen.dart';

/// Main dashboard screen for AgriAI app
/// Provides navigation to all features and overview information
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  app_user.User? _currentUser;
  List<MarketPrice> _recentPrices = [];
  Weather? _currentWeather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load dashboard data
  Future<void> _loadDashboardData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (authService.currentUser != null) {
        // Use current user from AuthService
        _currentUser = authService.currentUser;
        
        // Load recent market prices
        _recentPrices = await _apiService.fetchMarketPrices();
        _recentPrices = _recentPrices.take(3).toList();
        
        // Load current weather
        _currentWeather = await _apiService.fetchWeatherData('Bangalore');
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AgriAI Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardData();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  _showProfileDialog();
                  break;
                case 'logout':
                  await _handleLogout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    
                    // Quick stats
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    
                    // Main features grid
                    _buildFeaturesGrid(),
                    const SizedBox(height: 24),
                    
                    // Recent market prices
                    if (_recentPrices.isNotEmpty) ...[
                      _buildRecentPricesSection(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Weather overview
                    if (_currentWeather != null) ...[
                      _buildWeatherSection(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Tips section
                    _buildTipsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                Text(
                  _currentUser?.name ?? 'Farmer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentUser?.userType.toUpperCase() ?? 'FARMER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.agriculture,
            size: 60,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  /// Build quick stats section
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Weather',
            _currentWeather?.weatherIcon ?? '🌤️',
            '${_currentWeather?.temperature.toInt() ?? 25}°C',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Soil Type',
            '🌱',
            _currentUser?.soilType.toUpperCase() ?? 'ALLUVIAL',
            Colors.brown,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Land Area',
            '🌾',
            _currentUser?.landAreaAcres != null ? '${_currentUser!.landAreaAcres.toStringAsFixed(1)} acres' : '0.0 acres',
            Colors.green,
          ),
        ),
      ],
    );
  }

  /// Build stat card
  Widget _buildStatCard(String title, String icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build features grid
  Widget _buildFeaturesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _buildFeatureCard(
              'Crop Suggestion',
              Icons.eco,
              Colors.green,
              'Get recommendations based on soil and weather',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CropSuggestionScreen()),
              ),
            ),
            _buildFeatureCard(
              'Fertilizer Tips',
              Icons.grass,
              Colors.orange,
              'Find the right fertilizer for your crops',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FertilizerTipsScreen()),
              ),
            ),
            _buildFeatureCard(
              '🌱 AI Fertilizer Recommendation',
              Icons.science,
              Colors.green,
              'AI-powered NPK analysis & crop-specific recommendations',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FertilizerRecommendationScreen()),
              ),
            ),
            _buildFeatureCard(
              'Market Prices',
              Icons.trending_up,
              Colors.blue,
              'Check latest crop prices in markets',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketPriceScreen()),
              ),
            ),
            _buildFeatureCard(
              'Weather Info',
              Icons.wb_sunny,
              Colors.amber,
              'Get weather updates and forecasts',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeatherScreen()),
              ),
            ),
            _buildFeatureCard(
              'Disease Detection',
              Icons.healing,
              Colors.red,
              'Identify crop diseases with AI',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DiseaseDetectionScreen()),
              ),
            ),
            _buildFeatureCard(
              'Soil Based Recommendation',
              Icons.analytics,
              Colors.teal,
              'Get crop recommendations based on soil analysis',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SoilBasedRecommendationScreen()),
              ),
            ),
            _buildFeatureCard(
              'Marketplace',
              Icons.store,
              Colors.purple,
              'Buy and sell crops directly',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketplaceScreen()),
              ),
            ),
            _buildFeatureCard(
              'AI Assistant',
              Icons.smart_toy,
              Colors.deepOrange,
              'Get AI-powered farming advice',
              () => _showComingSoonDialog('AI Assistant'),
            ),
          ],
        ),
      ],
    );
  }

  /// Build feature card
  Widget _buildFeatureCard(
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Back to withOpacity for compatibility
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build recent prices section
  Widget _buildRecentPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Prices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketPriceScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentPrices.length,
            itemBuilder: (context, index) {
              final price = _recentPrices[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.cropName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${price.price.toInt()}/quintal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          price.changePercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: price.changePercentage >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          price.formattedChange,
                          style: TextStyle(
                            fontSize: 12,
                            color: price.changePercentage >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build weather section
  Widget _buildWeatherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weather Today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeatherScreen()),
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                _currentWeather!.weatherIcon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentWeather!.temperature.toInt()}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentWeather!.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Humidity: ${_currentWeather!.humidity.toInt()}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentWeather!.farmingAdvice,
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build tips section
  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farming Tips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildTipItem(
                '🌱',
                'Soil Health',
                'Test your soil pH regularly for optimal crop growth',
              ),
              const Divider(),
              _buildTipItem(
                '💧',
                'Water Management',
                'Use drip irrigation to conserve water and improve yield',
              ),
              const Divider(),
              _buildTipItem(
                '🌾',
                'Crop Rotation',
                'Rotate crops to maintain soil fertility and reduce pests',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build tip item
  Widget _buildTipItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  /// Show profile dialog
  void _showProfileDialog() {
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.person, size: 40, color: Colors.green.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentUser?.name ?? 'User',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _currentUser?.email ?? 'No email',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileItem(Icons.agriculture, 'User Type', _currentUser?.userType ?? 'Farmer'),
                _buildProfileItem(Icons.terrain, 'Soil Type', _currentUser?.soilType ?? 'Not specified'),
                _buildProfileItem(Icons.landscape, 'Land Area', _currentUser?.landAreaAcres != null 
                    ? '${_currentUser!.landAreaAcres.toStringAsFixed(1)} acres' : 'Not specified'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditProfileDialog();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    // Logout functionality removed
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show edit profile dialog
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _currentUser?.name ?? '');
    final soilTypes = ['alluvial', 'black', 'red', 'laterite', 'desert', 'mountain', 'loamy', 'sandy', 'clay'];
    
    // Ensure selectedSoilType is a valid value from the soilTypes list
    String userSoilType = _currentUser?.soilType ?? 'alluvial';
    String selectedSoilType = soilTypes.contains(userSoilType) ? userSoilType : 'alluvial';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSoilType,
                      decoration: const InputDecoration(
                        labelText: 'Soil Type',
                        border: OutlineInputBorder(),
                      ),
                      items: soilTypes.map((soil) {
                        return DropdownMenuItem(
                          value: soil,
                          child: Text(soil.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSoilType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentUser != null) {
                      // Update user data
                      final updatedUser = _currentUser!.copyWith(
                        name: nameController.text,
                        soilType: selectedSoilType,
                      );
                      
                      // Save to Firestore
                      final firestoreService = FirestoreService();
                      await firestoreService.updateUser(updatedUser);
                      
                      // Update local state
                      setState(() {
                        _currentUser = updatedUser;
                      });
                      
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show coming soon dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feature),
          content: const Text('This feature is coming soon! Stay tuned for updates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}