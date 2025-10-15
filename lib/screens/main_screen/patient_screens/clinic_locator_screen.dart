import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/directions_service.dart';
import '../../../utils/connectivity_helper.dart';

class ClinicLocatorScreen extends StatefulWidget {
  const ClinicLocatorScreen({super.key});

  @override
  State<ClinicLocatorScreen> createState() => _ClinicLocatorScreenState();
}

class _ClinicLocatorScreenState extends State<ClinicLocatorScreen> {
  GoogleMapController? _mapController;
  String selectedType = "clinic";
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _showList = false;
  bool _isMapReady = false;
  bool _hasMapError = false;
  String? _mapErrorMessage;
  bool _isCreatingRoute = false;
  bool _showTodayOnly = true; // Toggle for showing today's clinics only

  final Set<Polyline> _polylines = {};
  Map<String, dynamic>? _selectedLocation;
  final DirectionsService _directionsService = DirectionsService();
  RouteInfo? _currentRoute;
  bool _isLoadingRoute = false;

  // Enhanced clinics data with distance calculation support
  List<Map<String, dynamic>> clinics = [
    {
      'name': 'Dr. Heide P. Abdurahman',
      'type': 'Adult Hematologist',
      'address':
          'Metro Davao Medical & Research Center, J.P. Laurel Ave, Bajada, Davao City',
      'lat': '7.095116',
      'lng': '125.613161',
      'contact': '09099665139',
      'schedule': 'Wed & Fri 1-6 PM',
      'availableDays': ['Wednesday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Lilia Matildo Yu',
      'type': 'Pediatric Hematologist',
      'address':
          'Medical Arts Building, front of San Pedro Hospital, Guerrero St., Davao City',
      'lat': '7.078266',
      'lng': '125.614739',
      'contact': 'Call for info',
      'schedule': 'By appointment',
      'availableDays': [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Jeannie B. Ong',
      'type': 'Pediatric Hematologist',
      'address': 'San Pedro Hospital, Guzman St., Davao City',
      'lat': '7.078959',
      'lng': '125.614977',
      'contact': '09924722148',
      'schedule': 'Mon, Thu & Fri 10 AM-1 PM',
      'availableDays': ['Monday', 'Thursday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    // New Hematologists from SeriousMD
    {
      'name': 'Dr. Anne Kristine Quero',
      'type': 'Adult Hematologist',
      'address': 'San Juan De Dios Hospital, 2772 Roxas Boulevard, Pasay City',
      'lat': '14.5378',
      'lng': '120.9897',
      'contact': '(02)8831-9731 ext 1246',
      'schedule': 'Tue 9 AM-12 PM, Thu 2-5 PM',
      'availableDays': ['Tuesday', 'Thursday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Anne Kristine Quero',
      'type': 'Adult Hematologist',
      'address': 'MyHealth Clinic, 3rd floor Robinsons Place Ermita',
      'lat': '14.5799',
      'lng': '120.9842',
      'contact': '09165868535',
      'schedule': 'Wed 2-5 PM',
      'availableDays': ['Wednesday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Anne Kristine Quero',
      'type': 'Adult Hematologist',
      'address': 'Healthway Clinic, 8 Adriatico Manila',
      'lat': '14.5799',
      'lng': '120.9842',
      'contact': '09178479722',
      'schedule': 'Mon 4-6 PM, Fri 2-4 PM',
      'availableDays': ['Monday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Anne Kristine Quero',
      'type': 'Adult Hematologist',
      'address': 'Healthway Cancer Care Hospital, South Union Dr, Arca South',
      'lat': '14.4103',
      'lng': '121.0431',
      'contact': '(02)7777-4673',
      'schedule': 'Wed & Fri 10 AM-12 PM',
      'availableDays': ['Wednesday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Deonne Thaddeus Gauiran',
      'type': 'Adult Hematologist',
      'address':
          'UP-PGH Faculty Medical Arts Building, Taft Ave., Ermita, Manila',
      'lat': '14.5799',
      'lng': '120.9842',
      'contact': 'Book via SeriousMD',
      'schedule': 'Tue 1-5 PM, Fri 9 AM-12 PM',
      'availableDays': ['Tuesday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Deonne Thaddeus Gauiran',
      'type': 'Adult Hematologist',
      'address': 'Healthway Cancer Care Hospital, South Union Dr, Arca South',
      'lat': '14.4103',
      'lng': '121.0431',
      'contact': 'Book via SeriousMD',
      'schedule': 'Wed 3:30-5:30 PM',
      'availableDays': ['Wednesday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Deonne Thaddeus Gauiran',
      'type': 'Adult Hematologist',
      'address': 'San Juan De Dios Hospital, 2772 Roxas Boulevard, Pasay City',
      'lat': '14.5378',
      'lng': '120.9897',
      'contact': 'Book via SeriousMD',
      'schedule': 'Mon 1:30-4 PM',
      'availableDays': ['Monday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Kristian Dorell Masacupan',
      'type': 'Pediatric Hematologist',
      'address': 'Davao Doctors Hospital, 118 E, Quirino Avenue, Davao City',
      'lat': '7.0731',
      'lng': '125.6128',
      'contact': 'Book via SeriousMD',
      'schedule': 'Thu 10 AM-12 PM',
      'availableDays': ['Thursday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Nemuel Valmoria',
      'type': 'Adult Hematologist',
      'address':
          'UCMed Medical Arts Building Suite 218, Ouano Avenue, Subangdaku, Mandaue City',
      'lat': '10.3458',
      'lng': '123.9486',
      'contact': 'Book via SeriousMD',
      'schedule': 'Tue & Thu 8-10 AM',
      'availableDays': ['Tuesday', 'Thursday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Nemuel Valmoria',
      'type': 'Adult Hematologist',
      'address': 'MDH Medical Arts Building Room 204, Basak, Lapu-Lapu City',
      'lat': '10.3103',
      'lng': '123.9494',
      'contact': 'Book via SeriousMD',
      'schedule': 'Mon & Fri 9-11 AM',
      'availableDays': ['Monday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Jose Antonio S. Quitevis',
      'type': 'Hematology/Oncology',
      'address': 'Cebu Doctors\' Group, Rm. 215 - MAB 2, Cebu City',
      'lat': '10.3157',
      'lng': '123.8854',
      'contact': '(032)253-5200',
      'schedule': 'Mon-Sat 10 AM-12 PM, 12-2 PM',
      'availableDays': [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Katherine Benitez',
      'type': 'Adult Hematologist',
      'address': 'Perpetual Help Hospital Biñan, National Highway, Biñan City',
      'lat': '14.3394',
      'lng': '121.0831',
      'contact': '0962 770 7354',
      'schedule': 'Wed 1-3 PM, Fri 9 AM-12 PM',
      'availableDays': ['Wednesday', 'Friday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Katherine Benitez',
      'type': 'Adult Hematologist',
      'address':
          'The Medical City-South Luzon, Greenfield City, Brgy. Don Jose, Santa Rosa City',
      'lat': '14.3119',
      'lng': '121.1114',
      'contact': '0906 780 9638',
      'schedule': 'Tue 11 AM-1 PM',
      'availableDays': ['Tuesday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Katherine Benitez',
      'type': 'Adult Hematologist',
      'address': 'Biñan Doctors Hospital, Inc., Platero, Biñan City',
      'lat': '14.3394',
      'lng': '121.0831',
      'contact': '0961 000 6594',
      'schedule': 'Wed 9:30-11:30 AM',
      'availableDays': ['Wednesday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Reynaldo Espinoza',
      'type': 'Adult Hematologist',
      'address': 'Nazareth General Hospital, Inc., 203 Perez St., Dagupan City',
      'lat': '15.9759',
      'lng': '120.3372',
      'contact': 'Book via SeriousMD',
      'schedule': 'Wed 9 AM-12 PM',
      'availableDays': ['Wednesday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Reynaldo Espinoza',
      'type': 'Adult Hematologist',
      'address':
          'The Medical City-Pangasinan, Nable Street, Pantal, Dagupan City',
      'lat': '15.9759',
      'lng': '120.3372',
      'contact': 'Book via SeriousMD',
      'schedule': 'Mon 2-4 PM',
      'availableDays': ['Monday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Reynaldo Espinoza',
      'type': 'Adult Hematologist',
      'address':
          'Blessed Family Doctors General Hospital, Ilang, San Carlos City',
      'lat': '15.9321',
      'lng': '120.3374',
      'contact': 'Book via SeriousMD',
      'schedule': 'Thu 1-3 PM',
      'availableDays': ['Thursday'],
      'distance': null,
      'distanceValue': double.infinity,
    },
  ];

  List<Map<String, dynamic>> drugOutlets = [
    {
      'name': 'Globo Asiatico Enterprises',
      'type': 'Medical Supply',
      'address': 'Door #4 Eldec Realty Bldg., Cabaguio Ave, Agdao, Davao City',
      'lat': '7.0894',
      'lng': '125.6232',
      'contact': '+63 82 224 1234',
      'schedule': 'Mon-Sat 8 AM-6 PM',
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'CLE Bio and Medical Supply',
      'type': 'Medical Supply',
      'address':
          '#003 Chiong Bldg, Flyover, Buhangin (JP Laurel Ave), Davao City',
      'lat': '7.0968',
      'lng': '125.6152',
      'contact': '+63 82 234 5678',
      'schedule': 'Mon-Fri 9 AM-5 PM',
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Kris Santonil - GB Distributor',
      'type': 'Online Drug Outlet',
      'address': 'Visayas - Nationwide online delivery available',
      'lat': null,
      'lng': null,
      'contact': '09336713883',
      'phone': '09336713883',
      'schedule': 'Online 24/7 - Call for orders',
      'distance': 'Online',
      'distanceValue': 0,
      'online': true,
      'viber': '+639336713883',
      'services': [
        'Phone Orders',
        'Viber Orders',
        'Free Messages',
        'Online Purchase'
      ],
      'noLocation': true,
    },
  ];

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _safeInitialization();

    // Add a periodic timer to refresh clinic availability every minute
    // This ensures that if the day changes while the app is open, the clinics update
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        final newDay = _getCurrentDay();
        print('⏰ Periodic check: Current day is $newDay');
        setState(() {
          // This will trigger a rebuild and re-filter the clinics
        });
        _updateMarkers();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    try {
      _mapController?.dispose();
    } catch (e) {
      print('Error disposing map controller: $e');
    }
    super.dispose();
  }

  Future<void> _safeInitialization() async {
    try {
      print('🗺️ Starting clinic locator initialization...');

      // Add a small delay to ensure the widget is fully built
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) {
        print('❌ Widget unmounted during initialization');
        return;
      }

      setState(() {
        _isMapReady = false;
        _hasMapError = false;
      });

      print('🌍 Initializing location services...');

      // Initialize location with timeout
      await Future.any([
        _initializeLocation(),
        Future.delayed(const Duration(seconds: 10), () {
          throw Exception('Location initialization timeout');
        }),
      ]);

      if (!mounted) {
        print('❌ Widget unmounted after location init');
        return;
      }

      print('📍 Updating markers...');

      // Then update markers
      _updateMarkers();

      // Add another delay before marking map as ready to allow Google Maps to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        print('❌ Widget unmounted before map ready');
        return;
      }

      print('✅ Map initialization complete');

      setState(() {
        _isMapReady = true;
      });
    } catch (e) {
      print('❌ Error during safe initialization: $e');
      if (mounted) {
        setState(() {
          _hasMapError = true;
          _mapErrorMessage = 'Initialization error: ${e.toString()}';
        });

        // Provide fallback to list view
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _hasMapError) {
            setState(() {
              _showList = true;
            });
          }
        });
      }
    }
  }

  Widget _buildMapWidget() {
    // Show loading while map is initializing
    if (!_isMapReady) {
      return _buildMapLoadingWidget();
    }

    // Show error if there's a map error
    if (_hasMapError) {
      return _buildMapErrorWidget();
    }

    return FutureBuilder<Widget>(
      future: _createSafeGoogleMap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMapLoadingWidget();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasMapError = true;
                _mapErrorMessage =
                    'Map initialization failed: ${snapshot.error ?? 'Unknown error'}';
              });
            }
          });
          return _buildMapErrorWidget();
        }

        return snapshot.data!;
      },
    );
  }

  Future<Widget> _createSafeGoogleMap() async {
    try {
      // Add a small delay to prevent rapid initialization
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) {
        throw Exception('Widget no longer mounted');
      }

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                )
              : const LatLng(7.0731, 125.6128),
          zoom: 13,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) {
          _handleMapCreated(controller);
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        // Simplified options to reduce complexity
        liteModeEnabled: false,
        // Add error handling for map rendering
        onCameraMoveStarted: () {
          // Map is responding, clear any previous errors
          if (_hasMapError && mounted) {
            setState(() {
              _hasMapError = false;
              _mapErrorMessage = null;
            });
          }
        },
      );
    } catch (e) {
      print('❌ Error creating Google Map: $e');
      throw e;
    }
  }

  void _handleMapCreated(GoogleMapController controller) {
    try {
      if (!mounted) return;

      print('✅ Google Map created successfully');
      _mapController = controller;

      if (_currentPosition != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _centerMapOnUser();
          }
        });
      }
    } catch (e) {
      print('❌ Error in map created callback: $e');
      if (mounted) {
        setState(() {
          _hasMapError = true;
          _mapErrorMessage = 'Map setup error: ${e.toString()}';
        });
      }
    }
  }

  Widget _buildMapLoadingWidget() {
    return Container(
      color: Colors.grey[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Loading Map...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we initialize the clinic locator',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Map Unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _mapErrorMessage ??
                    'Unable to load the map. Please check your connection.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _retryMapInitialization();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showList = true;
                  });
                },
                child: const Text(
                  'View List Instead',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retryMapInitialization() {
    setState(() {
      _hasMapError = false;
      _mapErrorMessage = null;
      _isMapReady = false;
    });
    _safeInitialization();
  }

  Future<void> _initializeLocation() async {
    try {
      // Try to get location on app start
      await _getCurrentLocation();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  // 📍 Enhanced Current Location Detection
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          setState(() {
            _isLoadingLocation = false;
          });
          _showErrorMessage(
              'Location permission is required to find nearby clinics');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        setState(() {
          _isLoadingLocation = false;
        });
        _showErrorMessage('Please enable location permission in settings');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        setState(() {
          _isLoadingLocation = false;
        });
        _showErrorMessage('Please enable location services');
        return;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // 📏 Calculate distances and update UI
      _calculateAllDistances();
      _updateMarkers();
      _centerMapOnUser();

      print('Location acquired: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
      _showErrorMessage('Unable to get current location: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 📏 Enhanced Distance Calculation
  void _calculateAllDistances() {
    if (_currentPosition == null) return;

    try {
      // Calculate distances for clinics
      for (int i = 0; i < clinics.length; i++) {
        final clinic = clinics[i];
        try {
          final lat = double.parse(clinic['lat'] ?? '0');
          final lng = double.parse(clinic['lng'] ?? '0');

          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );

          final distanceKm = distance / 1000;
          clinics[i]['distance'] = distanceKm.toStringAsFixed(1);
          clinics[i]['distanceValue'] = distanceKm;
        } catch (e) {
          print('Error parsing coordinates for clinic ${clinic['name']}: $e');
          clinics[i]['distance'] = 'N/A';
          clinics[i]['distanceValue'] = double.infinity;
        }
      }

      // Calculate distances for drug outlets
      for (int i = 0; i < drugOutlets.length; i++) {
        final outlet = drugOutlets[i];
        try {
          final lat = double.parse(outlet['lat'] ?? '0');
          final lng = double.parse(outlet['lng'] ?? '0');

          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );

          final distanceKm = distance / 1000;
          drugOutlets[i]['distance'] = distanceKm.toStringAsFixed(1);
          drugOutlets[i]['distanceValue'] = distanceKm;
        } catch (e) {
          print('Error parsing coordinates for outlet ${outlet['name']}: $e');
          drugOutlets[i]['distance'] = 'N/A';
          drugOutlets[i]['distanceValue'] = double.infinity;
        }
      }

      // 📊 Smart Sorting by distance
      _sortLocationsByDistance();
    } catch (e) {
      print('Error calculating distances: $e');
    }
  }

  // 📊 Smart Sorting Implementation
  void _sortLocationsByDistance() {
    clinics.sort((a, b) => a['distanceValue'].compareTo(b['distanceValue']));
    drugOutlets.sort(
      (a, b) => a['distanceValue'].compareTo(b['distanceValue']),
    );
  }

  // 🎨 Distance Color Coding Implementation
  Color _getDistanceColor(String? distance) {
    if (distance == null) return Colors.grey;

    double dist = double.tryParse(distance) ?? double.infinity;
    if (dist <= 2.0) return Colors.green; // Very close
    if (dist <= 5.0) return Colors.orange; // Moderate distance
    return Colors.red; // Far
  }

  // 🗺️ Enhanced Marker Updates with User Location
  void _updateMarkers() {
    if (!mounted) return; // Prevent updates on unmounted widget

    Set<Marker> markers = {};

    try {
      // Add user location marker (Green marker)
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(
              title: '📍 Your Location',
              snippet: 'You are here',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      // Add location markers based on selected type
      final currentData = _getCurrentDataList();
      for (var location in currentData) {
        try {
          // Safely parse coordinates with validation
          final latStr = location['lat'];
          final lngStr = location['lng'];
          final name = location['name'] ?? 'Unknown Location';

          if (latStr == null ||
              lngStr == null ||
              latStr.isEmpty ||
              lngStr.isEmpty) {
            print('Skipping location $name: Missing coordinates');
            continue;
          }

          final lat = double.tryParse(latStr);
          final lng = double.tryParse(lngStr);

          if (lat == null || lng == null) {
            print(
                'Skipping location $name: Invalid coordinates ($latStr, $lngStr)');
            continue;
          }

          // Validate coordinate ranges
          if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            print(
                'Skipping location $name: Coordinates out of range ($lat, $lng)');
            continue;
          }

          markers.add(
            Marker(
              markerId: MarkerId(name),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: location['distance'] != null
                    ? '${location['distance']} km • ${location['type'] ?? 'Location'}'
                    : location['type'] ?? 'Location',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                selectedType == "clinic"
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueBlue,
              ),
              onTap: () => _showLocationDetails(location),
            ),
          );
        } catch (e) {
          print('Error adding marker for ${location['name']}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
    } catch (e) {
      print('Error updating markers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating map markers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Center map on user location
  void _centerMapOnUser() {
    try {
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      print('Error centering map on user: $e');
      // Don't show snackbar for this error as it's not critical
    }
  }

  // Get current day of the week
  String _getCurrentDay() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[now.weekday - 1];
  }

  // Filter clinics by current day availability
  List<Map<String, dynamic>> _getAvailableClinics() {
    final currentDay = _getCurrentDay();
    print('🗓️ Current day: $currentDay');

    final filteredClinics = clinics.where((clinic) {
      // If clinic has availableDays, check if current day is included
      if (clinic['availableDays'] != null && clinic['availableDays'] is List) {
        final availableDays = clinic['availableDays'] as List<String>;
        final isAvailable = availableDays.contains(currentDay);
        print(
            '🏥 ${clinic['name']}: Available on $availableDays -> $isAvailable');
        return isAvailable;
      }
      // If no availableDays specified, assume available all days (for backwards compatibility)
      print('🏥 ${clinic['name']}: No schedule specified, showing all days');
      return true;
    }).toList();

    print(
        '📊 Filtered ${filteredClinics.length} clinics out of ${clinics.length} total');
    return filteredClinics;
  }

  // Get current data list based on selected type and filter mode
  List<Map<String, dynamic>> _getCurrentDataList() {
    if (selectedType == "clinic") {
      return _showTodayOnly ? _getAvailableClinics() : clinics;
    } else {
      return drugOutlets;
    }
  }

  // Show location details in a bottom sheet
  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationBottomSheet(location),
    );
  }

  // Bottom sheet widget for location details
  Widget _buildLocationBottomSheet(Map<String, dynamic> location) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedType == "clinic"
                        ? Colors.redAccent.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selectedType == "clinic"
                        ? FontAwesomeIcons.userDoctor
                        : (location['online'] == true
                            ? FontAwesomeIcons.globe
                            : FontAwesomeIcons.pills),
                    color: selectedType == "clinic"
                        ? Colors.redAccent
                        : (location['online'] == true
                            ? Colors.green
                            : Colors.blue),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        location['type'],
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedType == "clinic"
                              ? Colors.redAccent
                              : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (location['distance'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDistanceColor(
                        location['distance'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${location['distance']} km',
                      style: TextStyle(
                        color: _getDistanceColor(location['distance']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(FontAwesomeIcons.locationDot, location['address']),
            _buildCopyableContactRow(
                FontAwesomeIcons.phone, 'Phone', location['contact']),
            if (location['viber'] != null)
              _buildCopyableContactRow(
                  FontAwesomeIcons.viber, 'Viber', location['viber']),
            _buildInfoRow(FontAwesomeIcons.clock, location['schedule']),

            // Show online services if available
            if (location['online'] == true && location['services'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.globe,
                    color: Colors.green.shade600,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online Services Available:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (location['services'] as List<String>).map((service) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      service,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: location['online'] == true
                      ? ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(location['contact']),
                          icon: const Icon(FontAwesomeIcons.phone, size: 16),
                          label: const Text('Call Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isCreatingRoute
                              ? null
                              : () => _createRouteToLocation(location),
                          icon: _isCreatingRoute
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(FontAwesomeIcons.route, size: 16),
                          label: Text(
                              _isCreatingRoute ? 'Loading...' : 'Show Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == "clinic"
                                ? Colors.redAccent
                                : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableContactRow(IconData icon, String label, String contact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(contact, label),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        contact,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      FontAwesomeIcons.copy,
                      size: 12,
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createRouteToLocation(Map<String, dynamic> location) async {
    // Check connectivity first
    final isOnline = await ConnectivityHelper.isOnline();
    if (!isOnline) {
      ConnectivityHelper.showOfflineSnackBar(context);
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location not available. Please enable location services.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show travel mode selection dialog first
    final selectedMode = await _showTravelModeDialog();
    if (selectedMode == null) return;

    // Set loading state BEFORE closing modal to prevent blank screen
    setState(() {
      _isCreatingRoute = true;
      _isLoadingRoute = true;
      _selectedLocation = location;
      _polylines.clear();
    });

    // Show immediate loading feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Calculating route...'),
          ],
        ),
        backgroundColor:
            selectedType == "clinic" ? Colors.redAccent : Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    // Small delay to ensure loading state is visible
    await Future.delayed(const Duration(milliseconds: 100));

    // Close the bottom sheet/modal after setting loading state
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    try {
      final origin =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final destination = LatLng(
        double.parse(location['lat']!),
        double.parse(location['lng']!),
      );

      final routeInfo = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        travelMode: selectedMode,
      );

      if (routeInfo != null) {
        setState(() {
          _currentRoute = routeInfo;
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route_to_location'),
              points: routeInfo.polylinePoints,
              color: _getTravelModeColor(selectedMode),
              width: 5,
              patterns: selectedMode == TravelMode.walking
                  ? [PatternItem.dot, PatternItem.gap(10)]
                  : [],
            ),
          );
          _isLoadingRoute = false;
          _isCreatingRoute = false;
        });

        // Show route information
        _showRouteInfoSnackBar(routeInfo);
        _fitMapToShowRoute(routeInfo.polylinePoints);
      } else {
        setState(() {
          _isLoadingRoute = false;
          _isCreatingRoute = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Route service unavailable. Please check your internet connection.',
              style: TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _isCreatingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding route: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<TravelMode?> _showTravelModeDialog() async {
    return showDialog<TravelMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Select Travel Mode',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTravelModeOption(
                TravelMode.driving,
                FontAwesomeIcons.car,
                'Driving',
                'Fastest route by car',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildTravelModeOption(
                TravelMode.walking,
                FontAwesomeIcons.personWalking,
                'Walking',
                'Pedestrian route',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildTravelModeOption(
                TravelMode.motorcycle,
                FontAwesomeIcons.motorcycle,
                'Motorcycle/Bike',
                'Two-wheeler route',
                Colors.orange,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTravelModeOption(
    TravelMode mode,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Color _getTravelModeColor(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return Colors.blue;
      case TravelMode.walking:
        return Colors.green;
      case TravelMode.bicycling:
        return Colors.orange;
      case TravelMode.transit:
        return Colors.purple;
      case TravelMode.motorcycle:
        return Colors.red;
    }
  }

  void _showRouteInfoSnackBar(RouteInfo routeInfo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getTravelModeIcon(routeInfo.travelMode),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${routeInfo.distance} • ${routeInfo.duration}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _getTravelModeDisplayName(routeInfo.travelMode),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getTravelModeColor(routeInfo.travelMode),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getTravelModeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return FontAwesomeIcons.car;
      case TravelMode.walking:
        return FontAwesomeIcons.personWalking;
      case TravelMode.bicycling:
        return FontAwesomeIcons.bicycle;
      case TravelMode.motorcycle:
        return FontAwesomeIcons.motorcycle;
      case TravelMode.transit:
        return FontAwesomeIcons.bus;
    }
  }

  String _getTravelModeDisplayName(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'Driving route';
      case TravelMode.walking:
        return 'Walking route';
      case TravelMode.bicycling:
        return 'Bicycling route';
      case TravelMode.motorcycle:
        return 'Motorcycle/Bike route';
      case TravelMode.transit:
        return 'Public transit route';
    }
  }

  void _fitMapToShowRoute(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    try {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      print('Error fitting map to route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Access Care Locator',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: selectedType == "clinic"
                  ? Colors.redAccent.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: _toggleLocationType,
              icon: Icon(
                selectedType == "clinic"
                    ? FontAwesomeIcons.userDoctor
                    : FontAwesomeIcons.pills,
                size: 14,
                color:
                    selectedType == "clinic" ? Colors.redAccent : Colors.blue,
              ),
              label: Text(
                selectedType == "clinic" ? 'Clinics' : 'Outlets',
                style: TextStyle(
                  color:
                      selectedType == "clinic" ? Colors.redAccent : Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Large Map View with Error Handling
          Container(
            width: double.infinity,
            height: double.infinity,
            child: _buildMapWidget(),
          ),

          // Top Status Area
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status bar - white background only for content width
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedType == "clinic"
                                ? FontAwesomeIcons.userDoctor
                                : FontAwesomeIcons.pills,
                            color: selectedType == "clinic"
                                ? Colors.redAccent
                                : Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getCurrentDataList().isNotEmpty
                                ? '${_getCurrentDataList().length} ${selectedType == "clinic" ? "treatment centers" : "drug outlets"} found'
                                : 'Loading locations...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          if (_isLoadingLocation) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: selectedType == "clinic"
                                    ? Colors.redAccent
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // Day filter toggle for clinics
                if (selectedType == "clinic")
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleTodayFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showTodayOnly
                                  ? Colors.redAccent.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _showTodayOnly
                                      ? Colors.redAccent.withOpacity(0.3)
                                      : Colors.grey.shade300,
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open Today',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _showTodayOnly
                                        ? Colors.redAccent
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: _showTodayOnly ? 0 : 0.5,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _showTodayOnly
                                        ? FontAwesomeIcons.toggleOn
                                        : FontAwesomeIcons.toggleOff,
                                    size: 16,
                                    color: _showTodayOnly
                                        ? Colors.redAccent
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Spacer to push other content to the right if needed
                        const Spacer(),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Route Information Panel
          if (_currentRoute != null && !_isLoadingRoute)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTravelModeColor(_currentRoute!.travelMode)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTravelModeIcon(_currentRoute!.travelMode),
                        color: _getTravelModeColor(_currentRoute!.travelMode),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_currentRoute!.distance} • ${_currentRoute!.duration}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getTravelModeDisplayName(
                                _currentRoute!.travelMode),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedLocation != null)
                      Text(
                        'to ${_selectedLocation!['name']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // List Toggle Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _showList = !_showList;
                      });
                      if (_showList) {
                        _showLocationsList();
                      }
                    },
                    icon: Icon(
                      FontAwesomeIcons.list,
                      color: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // My Location Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _getCurrentLocation,
                    icon: Icon(
                      FontAwesomeIcons.locationCrosshairs,
                      color: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                    ),
                  ),
                ),

                const Spacer(),

                // Route Loading Indicator
                if (_isLoadingRoute)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: selectedType == "clinic"
                              ? Colors.redAccent
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ),

                // Clear Route Button (if route exists)
                if (_polylines.isNotEmpty && !_isLoadingRoute)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _polylines.clear();
                          _selectedLocation = null;
                          _currentRoute = null;
                        });
                      },
                      icon: Icon(
                        FontAwesomeIcons.xmark,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Route Loading Overlay (Full Screen)
          if (_isLoadingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: selectedType == "clinic"
                              ? Colors.redAccent
                              : Colors.blue,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Calculating Route...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please wait while we find the best path',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleLocationType() {
    setState(() {
      selectedType = selectedType == "clinic" ? "drug" : "clinic";
      _polylines.clear();
      _selectedLocation = null;
      _currentRoute = null;
    });
    _updateMarkers();
  }

  void _toggleTodayFilter() {
    setState(() {
      _showTodayOnly = !_showTodayOnly;
      _polylines.clear();
      _selectedLocation = null;
      _currentRoute = null;
    });
    _updateMarkers();
  }

  void _showLocationsList() {
    final dataList = _getCurrentDataList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      selectedType == "clinic"
                          ? FontAwesomeIcons.userDoctor
                          : FontAwesomeIcons.pills,
                      color: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedType == "clinic"
                            ? 'Treatment Centers'
                            : 'Drug Outlets',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${dataList.length} found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade200),

              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    final item = dataList[index];
                    return _buildLocationListItem(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationListItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedType == "clinic"
                      ? Colors.redAccent.withOpacity(0.1)
                      : (item['online'] == true
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selectedType == "clinic"
                      ? FontAwesomeIcons.userDoctor
                      : (item['online'] == true
                          ? FontAwesomeIcons.globe
                          : FontAwesomeIcons.pills),
                  color: selectedType == "clinic"
                      ? Colors.redAccent
                      : (item['online'] == true ? Colors.green : Colors.blue),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      item['type'],
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedType == "clinic"
                            ? Colors.redAccent
                            : (item['online'] == true
                                ? Colors.green
                                : Colors.blue),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (item['distance'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDistanceColor(item['distance']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item['distance']} km',
                    style: TextStyle(
                      color: _getDistanceColor(item['distance']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['address'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          // Show hint for online outlets
          if (item['online'] == true && item['phone'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tap for info • Long press to call • Tap numbers to copy',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Show route button only for non-online outlets
              if (item['online'] != true && item['noLocation'] != true) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingRoute
                        ? null
                        : () {
                            Navigator.pop(context);
                            _createRouteToLocation(item);
                          },
                    icon: _isCreatingRoute
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(FontAwesomeIcons.route, size: 14),
                    label: Text(_isCreatingRoute ? 'Loading...' : 'Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Info/Call button - expanded when no route button
              Expanded(
                flex: (item['online'] == true || item['noLocation'] == true)
                    ? 1
                    : 0,
                child: GestureDetector(
                  onLongPress: () {
                    // Long press for calling (online outlets only)
                    if (item['online'] == true && item['phone'] != null) {
                      _makePhoneCall(item['phone']);
                      // Show helpful message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Calling outlet...'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green.shade600,
                        ),
                      );
                    }
                  },
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Primary action is always to show details/info
                      _showLocationDetails(item);
                    },
                    icon: const Icon(FontAwesomeIcons.circleInfo, size: 16),
                    label: const Text('Info', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (item['online'] == true || item['noLocation'] == true)
                              ? Colors.blue.shade50
                              : Colors.grey.shade200,
                      foregroundColor:
                          (item['online'] == true || item['noLocation'] == true)
                              ? Colors.blue
                              : (item['online'] == true ||
                                      item['noLocation'] == true)
                                  ? Colors.blue
                                  : Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Make phone call to the outlet
  void _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make call to $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Copy text to clipboard with feedback
  void _copyToClipboard(String text, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied: $text'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy $label'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
