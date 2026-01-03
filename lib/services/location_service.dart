import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// LocationService
/// 
/// Handles all location-related operations in the app:
/// - Getting user's current GPS location
/// - Converting coordinates to addresses (reverse geocoding)
/// - Converting addresses to coordinates (forward geocoding)
/// - Calculating distances between locations
/// - Managing location permissions
/// 
/// USES:
/// - geolocator: For GPS coordinates and permissions
/// - geocoding: For address ↔ coordinates conversion
/// 
/// SINGLETON PATTERN:
/// Only one instance exists, accessible via LocationService()
class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled on the device
  /// 
  /// Returns: true if GPS is turned on, false otherwise
  /// 
  /// Note: This checks the device setting, not app permissions
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  /// 
  /// Flow:
  /// 1. Check current permission status
  /// 2. If denied, request permission from user
  /// 3. If permanently denied, throw error (user must enable in settings)
  /// 
  /// Returns: The permission status after checking/requesting
  /// 
  /// Throws: Exception if permissions are denied or permanently denied
  Future<LocationPermission> checkPermissions() async {
    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    
    // If denied, ask user for permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    // If permanently denied, user must enable in settings
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    }
    
    return permission;
  }

  /// Get current GPS position
  /// 
  /// Flow:
  /// 1. Check if location services are enabled
  /// 2. Check/request permissions
  /// 3. Get current coordinates with high accuracy
  /// 
  /// Returns: Position object with latitude, longitude, altitude, etc.
  /// 
  /// Throws: Exception if services disabled or permissions denied
  /// 
  /// Usage example:
  /// ```dart
  /// Position pos = await LocationService().getCurrentPosition();
  /// print('Lat: ${pos.latitude}, Lng: ${pos.longitude}');
  /// ```
  Future<Position> getCurrentPosition() async {
    // Step 1: Check if GPS is turned on
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in settings.');
    }

    // Step 2: Check permissions
    await checkPermissions();

    // Step 3: Get current position with high accuracy
    // high accuracy uses GPS, less accurate modes use WiFi/cell towers
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get address from coordinates (reverse geocoding)
  /// 
  /// Converts GPS coordinates to a human-readable address
  /// 
  /// Flow:
  /// 1. Query geocoding service with coordinates
  /// 2. Parse the first result
  /// 3. Format as "Street, City, State, Country"
  /// 
  /// Parameters:
  /// - latitude: GPS latitude
  /// - longitude: GPS longitude
  /// 
  /// Returns: Formatted address string
  /// 
  /// Example:
  /// Input: (37.7749, -122.4194)
  /// Output: "Market St, San Francisco, CA, USA"
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Get address information from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format address from components
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return 'Unknown location';
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  /// Get coordinates from address (forward geocoding)
  /// 
  /// Converts a text address to GPS coordinates
  /// 
  /// Flow:
  /// 1. Query geocoding service with address string
  /// 2. Return first matching location
  /// 3. Return null if no matches found
  /// 
  /// Parameters:
  /// - address: Text address to search for
  /// 
  /// Returns: Location object with latitude/longitude, or null if not found
  /// 
  /// Example:
  /// Input: "Panabo City"
  /// Output: Location(lat: 7.5089, lng: 125.6844)
  /// 
  /// Note: Returns null instead of throwing to allow graceful handling
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      // Search for address and get possible matches
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first; // Return best match
      }
      return null;
    } catch (e) {
      // Return null instead of throwing to allow graceful handling
      print('Geocoding error for "$address": $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  /// 
  /// Uses the Haversine formula to calculate great-circle distance
  /// (straight line distance on Earth's surface)
  /// 
  /// Parameters:
  /// - start: Latitude and longitude of first point
  /// - end: Latitude and longitude of second point
  /// 
  /// Returns: Distance in kilometers
  /// 
  /// Example:
  /// Distance between two posts to sort by proximity
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Geolocator returns distance in meters
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Get live location updates
  /// 
  /// Returns a stream of position updates as the user moves
  /// 
  /// Useful for:
  /// - Live tracking
  /// - Navigation
  /// - Real-time distance calculations
  /// 
  /// Returns: Stream that emits Position whenever location changes
  /// 
  /// Usage example:
  /// ```dart
  /// LocationService().getPositionStream().listen((position) {
  ///   print('Moved to: ${position.latitude}, ${position.longitude}');
  /// });
  /// ```
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when user moves 10 meters
      ),
    );
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
