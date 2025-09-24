import 'package:flutter/material.dart';
import '../models/fertilizer.dart';
import '../widgets/fertilizer_card.dart';
import '../services/api_service.dart';

/// Fertilizer tips screen for AgriAI app
/// Provides fertilizer recommendations and information
class FertilizerTipsScreen extends StatefulWidget {
  const FertilizerTipsScreen({super.key});

  @override
  State<FertilizerTipsScreen> createState() => _FertilizerTipsScreenState();
}

class _FertilizerTipsScreenState extends State<FertilizerTipsScreen> {
  final ApiService _apiService = ApiService();
  
  List<Fertilizer> _allFertilizers = [];
  List<Fertilizer> _filteredFertilizers = [];
  bool _isLoading = true;
  String _selectedCropType = '';
  String _selectedFertilizerType = '';
  double _acreage = 1.0;

  final List<String> _cropTypes = [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Vegetables',
    'Fruits',
    'Pulses',
  ];

  final List<String> _fertilizerTypes = [
    'organic',
    'inorganic',
    'bio-fertilizer',
  ];

  @override
  void initState() {
    super.initState();
    _loadFertilizers();
  }

  /// Load fertilizers data
  Future<void> _loadFertilizers() async {
    try {
      // Load real fertilizers from API
      _allFertilizers = await _apiService.fetchAllFertilizers();
      
      // If API fails, fallback to demo data
      if (_allFertilizers.isEmpty) {
        _loadDemoFertilizers();
      }
      
      _filteredFertilizers = List.from(_allFertilizers);
    } catch (e) {
      print('Error loading fertilizers: $e');
      // Fallback to demo data on error
      _loadDemoFertilizers();
      _filteredFertilizers = List.from(_allFertilizers);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Load demo fertilizers
  void _loadDemoFertilizers() {
    _allFertilizers = [
      Fertilizer(
        id: '1',
        name: 'NPK 20:10:10',
        cropType: 'Rice',
        recommendedQuantity: 125.0,
        type: 'inorganic',
        npkRatio: 20.0,
        applicationMethod: 'Broadcasting and soil incorporation',
        applicationTiming: 'Basal application before transplanting',
        pricePerKg: 25.0,
        description: 'Complete fertilizer with balanced NPK for rice cultivation',
        benefits: ['Balanced nutrition', 'Improved tillering', 'Better grain filling'],
        precautions: ['Store in dry place', 'Avoid contact with skin', 'Use protective gear'],
      ),
      Fertilizer(
        id: '2',
        name: 'Vermicompost',
        cropType: 'Vegetables',
        recommendedQuantity: 2000.0,
        type: 'organic',
        npkRatio: 2.0,
        applicationMethod: 'Soil mixing before planting',
        applicationTiming: '2-3 weeks before sowing',
        pricePerKg: 8.0,
        description: 'Organic fertilizer rich in nutrients and beneficial microorganisms',
        benefits: ['Improves soil structure', 'Enhances water retention', 'Eco-friendly'],
        precautions: ['Ensure proper composting', 'Check for pests', 'Store in ventilated area'],
      ),
      Fertilizer(
        id: '3',
        name: 'Urea',
        cropType: 'Wheat',
        recommendedQuantity: 87.0,
        type: 'inorganic',
        npkRatio: 46.0,
        applicationMethod: 'Broadcasting with irrigation',
        applicationTiming: 'Split application - 3 times',
        pricePerKg: 6.0,
        description: 'High nitrogen fertilizer for cereal crops',
        benefits: ['Quick nitrogen release', 'Promotes vegetative growth', 'Cost effective'],
        precautions: ['Avoid over-application', 'Apply with moisture', 'Store away from heat'],
      ),
    ];
  }

  /// Filter fertilizers
  void _filterFertilizers() {
    _filteredFertilizers = _allFertilizers.where((fertilizer) {
      bool matchesCrop = _selectedCropType.isEmpty || 
          fertilizer.cropType.toLowerCase().contains(_selectedCropType.toLowerCase());
      bool matchesType = _selectedFertilizerType.isEmpty || 
          fertilizer.type.toLowerCase() == _selectedFertilizerType.toLowerCase();
      return matchesCrop && matchesType;
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizer Tips'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters section
                _buildFiltersSection(),
                
                // Fertilizers list
                Expanded(
                  child: _buildFertilizersList(),
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
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Fertilizers',
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
                  initialValue: _selectedCropType.isEmpty ? null : _selectedCropType,
                  decoration: InputDecoration(
                    labelText: 'Crop Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Crops'),
                    ),
                    ..._cropTypes.map((crop) {
                      return DropdownMenuItem(
                        value: crop,
                        child: Text(crop),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCropType = value ?? '';
                      _filterFertilizers();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFertilizerType.isEmpty ? null : _selectedFertilizerType,
                  decoration: InputDecoration(
                    labelText: 'Fertilizer Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Types'),
                    ),
                    ..._fertilizerTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFertilizerType = value ?? '';
                      _filterFertilizers();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text('Farm Size: ${_acreage.toStringAsFixed(1)} acres'),
          Slider(
            value: _acreage,
            min: 0.5,
            max: 20.0,
            divisions: 39,
            label: '${_acreage.toStringAsFixed(1)} acres',
            onChanged: (value) {
              setState(() {
                _acreage = value;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Build fertilizers list
  Widget _buildFertilizersList() {
    if (_filteredFertilizers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No fertilizers found',
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

    return ListView.builder(
      itemCount: _filteredFertilizers.length,
      itemBuilder: (context, index) {
        final fertilizer = _filteredFertilizers[index];
        return FertilizerCard(
          fertilizer: fertilizer,
          acreage: _acreage,
          showCostCalculation: true,
          onTap: () => _showFertilizerDetails(fertilizer),
        );
      },
    );
  }

  /// Show fertilizer details
  void _showFertilizerDetails(Fertilizer fertilizer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(fertilizer.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fertilizer.description),
                const SizedBox(height: 16),
                
                Text(
                  'Application Details:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Method: ${fertilizer.applicationMethod}'),
                Text('Timing: ${fertilizer.applicationTiming}'),
                Text('Recommended Quantity: ${fertilizer.recommendedQuantity} kg/acre'),
                const SizedBox(height: 16),
                
                if (fertilizer.benefits.isNotEmpty) ...[
                  const Text(
                    'Benefits:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...fertilizer.benefits.map((benefit) => Text('• $benefit')),
                  const SizedBox(height: 16),
                ],
                
                if (fertilizer.precautions.isNotEmpty) ...[
                  const Text(
                    'Precautions:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  ...fertilizer.precautions.map((precaution) => Text('• $precaution')),
                ],
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
}