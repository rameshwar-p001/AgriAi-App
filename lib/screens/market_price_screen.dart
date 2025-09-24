import 'package:flutter/material.dart';
import '../models/market_price.dart';
import '../services/api_service.dart';
import '../widgets/market_price_card.dart';

/// Market price screen for AgriAI app
/// Shows current market prices for different crops
class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  final ApiService _apiService = ApiService();
  
  List<MarketPrice> _allPrices = [];
  List<MarketPrice> _filteredPrices = [];
  bool _isLoading = true;
  String _selectedCrop = '';
  String _selectedState = '';
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadMarketPrices();
  }

  /// Load market prices
  Future<void> _loadMarketPrices() async {
    try {
      _allPrices = await _apiService.fetchMarketPrices();
      _filteredPrices = List.from(_allPrices);
      _sortPrices();
    } catch (e) {
      print('Error loading market prices: $e');
      // Fallback: Load demo market price data
      _allPrices = _getDemoMarketPrices();
      _filteredPrices = List.from(_allPrices);
      _sortPrices();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Filter prices
  void _filterPrices() {
    _filteredPrices = _allPrices.where((price) {
      bool matchesCrop = _selectedCrop.isEmpty || 
          price.cropName.toLowerCase().contains(_selectedCrop.toLowerCase());
      bool matchesState = _selectedState.isEmpty || 
          price.state.toLowerCase().contains(_selectedState.toLowerCase());
      return matchesCrop && matchesState;
    }).toList();
    _sortPrices();
  }

  /// Sort prices
  void _sortPrices() {
    switch (_sortBy) {
      case 'price_high':
        _filteredPrices.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'price_low':
        _filteredPrices.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'change_high':
        _filteredPrices.sort((a, b) => b.changePercentage.compareTo(a.changePercentage));
        break;
      case 'change_low':
        _filteredPrices.sort((a, b) => a.changePercentage.compareTo(b.changePercentage));
        break;
      default:
        _filteredPrices.sort((a, b) => b.date.compareTo(a.date));
    }
    setState(() {});
  }

  /// Get unique crop names
  List<String> get _uniqueCrops {
    return _allPrices.map((price) => price.cropName).toSet().toList()..sort();
  }

  /// Get unique states
  List<String> get _uniqueStates {
    return _allPrices.map((price) => price.state).toSet().toList()..sort();
  }

  /// Get demo market prices for fallback
  List<MarketPrice> _getDemoMarketPrices() {
    return [
      MarketPrice(
        id: 'demo1',
        cropName: 'Rice',
        price: 3500.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        market: 'Pune Agricultural Market',
        state: 'Maharashtra',
        minPrice: 3200.0,
        maxPrice: 3800.0,
        priceType: 'wholesale',
        changePercentage: 2.5,
      ),
      MarketPrice(
        id: 'demo2',
        cropName: 'Wheat',
        price: 4200.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 3)),
        market: 'Agra Grain Market',
        state: 'Uttar Pradesh',
        minPrice: 4000.0,
        maxPrice: 4400.0,
        priceType: 'wholesale',
        changePercentage: -1.2,
      ),
      MarketPrice(
        id: 'demo3',
        cropName: 'Tomato',
        price: 2500.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        market: 'Bangalore Vegetable Market',
        state: 'Karnataka',
        minPrice: 2200.0,
        maxPrice: 2800.0,
        priceType: 'wholesale',
        changePercentage: 5.8,
      ),
      MarketPrice(
        id: 'demo4',
        cropName: 'Onion',
        price: 3000.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 4)),
        market: 'Jodhpur Agricultural Market',
        state: 'Rajasthan',
        minPrice: 2800.0,
        maxPrice: 3200.0,
        priceType: 'wholesale',
        changePercentage: 3.1,
      ),
      MarketPrice(
        id: 'demo5',
        cropName: 'Cotton',
        price: 5500.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        market: 'Surat Cotton Market',
        state: 'Gujarat',
        minPrice: 5200.0,
        maxPrice: 5800.0,
        priceType: 'wholesale',
        changePercentage: -0.8,
      ),
      MarketPrice(
        id: 'demo6',
        cropName: 'Soybean',
        price: 4800.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        market: 'Indore Agricultural Market',
        state: 'Madhya Pradesh',
        minPrice: 4600.0,
        maxPrice: 5000.0,
        priceType: 'wholesale',
        changePercentage: 1.9,
      ),
      MarketPrice(
        id: 'demo7',
        cropName: 'Sugarcane',
        price: 3200.0,
        unit: 'quintal',
        date: DateTime.now().subtract(const Duration(hours: 7)),
        market: 'Lucknow Sugar Market',
        state: 'Uttar Pradesh',
        minPrice: 3000.0,
        maxPrice: 3400.0,
        priceType: 'wholesale',
        changePercentage: 0.5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMarketPrices();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters and sort section
                _buildFiltersSection(),
                
                // Prices list
                Expanded(
                  child: _buildPricesList(),
                ),
              ],
            ),
    );
  }

  /// Build filters section
  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter & Sort',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCrop.isEmpty ? null : _selectedCrop,
                  decoration: InputDecoration(
                    labelText: 'Crop',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Crops'),
                    ),
                    ..._uniqueCrops.map((crop) {
                      return DropdownMenuItem(
                        value: crop,
                        child: Text(crop),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCrop = value ?? '';
                      _filterPrices();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedState.isEmpty ? null : _selectedState,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All States'),
                    ),
                    ..._uniqueStates.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value ?? '';
                      _filterPrices();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            initialValue: _sortBy,
            decoration: InputDecoration(
              labelText: 'Sort By',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
            items: [
              const DropdownMenuItem(value: 'date', child: Text('Latest First')),
              const DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              const DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const DropdownMenuItem(value: 'change_high', child: Text('Change: High to Low')),
              const DropdownMenuItem(value: 'change_low', child: Text('Change: Low to High')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
                _sortPrices();
              });
            },
          ),
        ],
      ),
    );
  }

  /// Build prices list
  Widget _buildPricesList() {
    if (_filteredPrices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No prices found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMarketPrices,
      child: ListView.builder(
        itemCount: _filteredPrices.length,
        itemBuilder: (context, index) {
          final price = _filteredPrices[index];
          return MarketPriceCard(
            marketPrice: price,
            onTap: () => _showPriceAnalysis(price),
          );
        },
      ),
    );
  }

  /// Show price analysis
  void _showPriceAnalysis(MarketPrice price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${price.cropName} Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Market: ${price.market}'),
              Text('State: ${price.state}'),
              Text('Current Price: ${price.formattedPrice}'),
              Text('Price Range: ₹${price.minPrice.toInt()} - ₹${price.maxPrice.toInt()}'),
              Text('Price Change: ${price.formattedChange}'),
              Text('Price Type: ${price.priceType.toUpperCase()}'),
              const SizedBox(height: 16),
              
              Text(
                'Price Trend:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                price.changePercentage > 0 
                    ? 'Prices are rising. Good time to sell.'
                    : price.changePercentage < 0
                        ? 'Prices are falling. Consider waiting.'
                        : 'Prices are stable.',
                style: TextStyle(
                  color: price.changePercentage > 0 
                      ? Colors.green 
                      : price.changePercentage < 0 
                          ? Colors.red 
                          : Colors.grey[600],
                ),
              ),
            ],
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
}