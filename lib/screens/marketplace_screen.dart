import 'package:flutter/material.dart';
import '../models/marketplace_listing.dart';
import '../models/user.dart' as app_user;
import '../services/api_service.dart';
import '../widgets/marketplace_card.dart';
import 'add_listing_screen.dart';

/// Marketplace screen for AgriAI app
/// Allows farmers to list crops and buyers to browse listings
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with TickerProviderStateMixin {
  
  late TabController _tabController;
  List<MarketplaceListing> _allListings = [];
  List<MarketplaceListing> _filteredListings = [];
  List<MarketplaceListing> _myListings = [];
  app_user.User? _currentUser;
  bool _isLoading = true;
  String _selectedCrop = '';
  String _selectedState = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load marketplace data from Firebase/API
  Future<void> _loadData() async {
    try {
      // Load marketplace listings from Firebase/API instead of dummy data
      final apiService = ApiService();
      _allListings = await apiService.fetchMarketplaceListings();
      
      _filteredListings = List.from(_allListings);
      
      // Load user's own listings if logged in
      if (_currentUser != null) {
        _myListings = await apiService.fetchMarketplaceListingsByFarmer(_currentUser!.id);
      } else {
        _myListings = [];
      }
    } catch (e) {
      print('Error loading marketplace data: $e');
      // Fallback: Load demo marketplace listings
      _allListings = _getDemoMarketplaceListings();
      _filteredListings = List.from(_allListings);
      _myListings = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Filter listings using API search
  Future<void> _filterListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      
      // Use API search for better performance with large datasets
      _filteredListings = await apiService.searchMarketplaceListings(
        cropName: _selectedCrop.isEmpty ? null : _selectedCrop,
        state: _selectedState.isEmpty ? null : _selectedState,
      );
    } catch (e) {
      print('Error filtering listings: $e');
      // Fallback to local filtering
      _filteredListings = _allListings.where((listing) {
        bool matchesCrop = _selectedCrop.isEmpty || 
            listing.cropName.toLowerCase().contains(_selectedCrop.toLowerCase());
        bool matchesState = _selectedState.isEmpty || 
            listing.state.toLowerCase().contains(_selectedState.toLowerCase());
        return matchesCrop && matchesState && listing.isAvailable;
      }).toList();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get unique crop names
  List<String> get _uniqueCrops {
    return _allListings.map((listing) => listing.cropName).toSet().toList()..sort();
  }

  /// Get unique states
  List<String> get _uniqueStates {
    return _allListings.map((listing) => listing.state).toSet().toList()..sort();
  }

  /// Get demo marketplace listings for fallback
  List<MarketplaceListing> _getDemoMarketplaceListings() {
    return [
      MarketplaceListing(
        id: 'demo1',
        farmerId: 'farmer1',
        farmerName: 'Ramesh Patil',
        contactPhone: '+91 9876543210',
        cropName: 'Rice',
        quantity: 5.0,
        unit: 'quintal',
        pricePerQuintal: 3500.0,
        description: 'Fresh organic rice, recently harvested',
        imageUrls: [],
        state: 'Maharashtra',
        location: 'Pune, Maharashtra',
        cropVariety: 'Basmati',
        qualityGrade: 'A',
        isOrganic: true,
        isAvailable: true,
        status: 'active',
        dateListed: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MarketplaceListing(
        id: 'demo2',
        farmerId: 'farmer2',
        farmerName: 'Suresh Kumar',
        contactPhone: '+91 9876543211',
        cropName: 'Wheat',
        quantity: 3.0,
        unit: 'quintal',
        pricePerQuintal: 4200.0,
        description: 'High quality wheat grains',
        imageUrls: [],
        state: 'Uttar Pradesh',
        location: 'Agra, Uttar Pradesh',
        cropVariety: 'Lokvan',
        qualityGrade: 'A',
        isOrganic: false,
        isAvailable: true,
        status: 'active',
        dateListed: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MarketplaceListing(
        id: 'demo3',
        farmerId: 'farmer3',
        farmerName: 'Lakshmi Devi',
        contactPhone: '+91 9876543212',
        cropName: 'Tomato',
        quantity: 2.0,
        unit: 'quintal',
        pricePerQuintal: 2500.0,
        description: 'Fresh red tomatoes, pesticide free',
        imageUrls: [],
        state: 'Karnataka',
        location: 'Bangalore, Karnataka',
        cropVariety: 'Hybrid',
        qualityGrade: 'A',
        isOrganic: true,
        isAvailable: true,
        status: 'active',
        dateListed: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MarketplaceListing(
        id: 'demo4',
        farmerId: 'farmer4',
        farmerName: 'Prakash Singh',
        contactPhone: '+91 9876543213',
        cropName: 'Onion',
        quantity: 4.0,
        unit: 'quintal',
        pricePerQuintal: 3000.0,
        description: 'Quality onions, good for long storage',
        imageUrls: [],
        state: 'Rajasthan',
        location: 'Jodhpur, Rajasthan',
        cropVariety: 'Red Onion',
        qualityGrade: 'B',
        isOrganic: false,
        isAvailable: true,
        status: 'active',
        dateListed: DateTime.now().subtract(const Duration(days: 4)),
      ),
      MarketplaceListing(
        id: 'demo5',
        farmerId: 'farmer5',
        farmerName: 'Gita Sharma',
        contactPhone: '+91 9876543214',
        cropName: 'Cotton',
        quantity: 1.5,
        unit: 'quintal',
        pricePerQuintal: 5500.0,
        description: 'Premium cotton, grade A quality',
        imageUrls: [],
        state: 'Gujarat',
        location: 'Surat, Gujarat',
        cropVariety: 'BT Cotton',
        qualityGrade: 'A',
        isOrganic: false,
        isAvailable: true,
        status: 'active',
        dateListed: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Browse', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'My Listings', icon: Icon(Icons.inventory)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(),
                _buildMyListingsTab(),
              ],
            ),
      floatingActionButton: _currentUser?.userType == 'farmer'
          ? FloatingActionButton.extended(
              onPressed: _showAddListingDialog,
              backgroundColor: Colors.purple[600],
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
            )
          : null,
    );
  }

  /// Build browse tab
  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Filters
        _buildFiltersSection(),
        
        // Listings
        Expanded(
          child: _buildListingsList(_filteredListings),
        ),
      ],
    );
  }

  /// Build my listings tab
  Widget _buildMyListingsTab() {
    return _buildListingsList(_myListings, isMyListings: true);
  }

  /// Build filters section
  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Listings',
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                      _filterListings();
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                      _filterListings();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build listings list
  Widget _buildListingsList(List<MarketplaceListing> listings, {bool isMyListings = false}) {
    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyListings ? Icons.inventory : Icons.shopping_cart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isMyListings ? 'No listings yet' : 'No listings found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMyListings 
                  ? 'Add your first listing to start selling'
                  : 'Try adjusting your filters',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return MarketplaceCard(
          listing: listing,
          isOwner: isMyListings,
          onTap: () => _showListingDetails(listing),
          onContact: () => _contactFarmer(listing),
          onEdit: isMyListings ? () => _editListing(listing) : null,
          onDelete: isMyListings ? () => _deleteListing(listing) : null,
        );
      },
    );
  }

  /// Show listing details
  void _showListingDetails(MarketplaceListing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(listing.cropName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Farmer: ${listing.farmerName}'),
                Text('Location: ${listing.location}, ${listing.state}'),
                Text('Quantity: ${listing.quantity} ${listing.unit}'),
                Text('Price: ${listing.formattedPrice}'),
                Text('Quality Grade: ${listing.qualityGrade}'),
                Text('Organic: ${listing.organicBadge}'),
                if (listing.cropVariety.isNotEmpty)
                  Text('Variety: ${listing.cropVariety}'),
                const SizedBox(height: 16),
                if (listing.description.isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(listing.description),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (listing.isAvailable)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _contactFarmer(listing);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Contact Farmer'),
              ),
          ],
        );
      },
    );
  }

  /// Contact farmer
  void _contactFarmer(MarketplaceListing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Farmer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact ${listing.farmerName} for ${listing.cropName}'),
              const SizedBox(height: 16),
              Text('Phone: ${listing.contactPhone}'),
              const SizedBox(height: 16),
              const Text(
                'You can call the farmer directly or the app will notify them of your interest.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Farmer has been notified of your interest!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Express Interest'),
            ),
          ],
        );
      },
    );
  }

  /// Show add listing screen
  void _showAddListingDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddListingScreen(),
      ),
    );
    
    // If a listing was added successfully, refresh the data
    if (result == true) {
      setState(() => _isLoading = true);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Edit listing
  void _editListing(MarketplaceListing listing) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit listing feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Delete listing
  void _deleteListing(MarketplaceListing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Listing'),
          content: Text('Are you sure you want to delete the listing for ${listing.cropName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Remove from demo data
                  setState(() {
                    _myListings.removeWhere((l) => l.id == listing.id);
                    _allListings.removeWhere((l) => l.id == listing.id);
                    _filterListings();
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting listing: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}