import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/user_service.dart';
import '../dio/resulr.dart';
import 'auth_provider.dart';

// Location state model
class LocationState {
  final LatLng? currentPosition;
  final LatLng? selectedPosition;
  final Set<Marker> markers;
  final bool isLoading;
  final String? error;
  final Map<String, String> addressDetails;
  final bool isSearching;
  final List<Map<String, dynamic>> searchSuggestions;
  final String searchQuery;
  final bool isSaving;

  LocationState({
    this.currentPosition,
    this.selectedPosition,
    this.markers = const {},
    this.isLoading = false,
    this.error,
    this.addressDetails = const {},
    this.isSearching = false,
    this.searchSuggestions = const [],
    this.searchQuery = '',
    this.isSaving = false,
  });

  LocationState copyWith({
    LatLng? currentPosition,
    LatLng? selectedPosition,
    Set<Marker>? markers,
    bool? isLoading,
    String? error,
    Map<String, String>? addressDetails,
    bool? isSearching,
    List<Map<String, dynamic>>? searchSuggestions,
    String? searchQuery,
    bool? isSaving,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      markers: markers ?? this.markers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      addressDetails: addressDetails ?? this.addressDetails,
      isSearching: isSearching ?? this.isSearching,
      searchSuggestions: searchSuggestions ?? this.searchSuggestions,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// Location notifier
class LocationNotifier extends StateNotifier<LocationState> {
  final UserService _userService;
  final Ref _ref;
  GoogleMapController? _mapController;
  
  // Default location (Delhi, India)
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  LocationNotifier(this._userService, this._ref) : super(LocationState()) {
    _getCurrentLocation();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check current permission status first
      final permissionStatus = await Permission.location.status;
      
      PermissionStatus permission;
      if (permissionStatus.isDenied) {
        // Request permission if not granted
        permission = await Permission.location.request();
      } else {
        permission = permissionStatus;
      }

      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        // Check if the location is reasonable (within India bounds approximately)
        if (position.latitude >= 6.0 && position.latitude <= 37.0 &&
            position.longitude >= 68.0 && position.longitude <= 97.0) {
          final latLng = LatLng(position.latitude, position.longitude);
          state = state.copyWith(
            currentPosition: latLng,
            selectedPosition: latLng,
            isLoading: false,
            error: null,
          );
          _addMarker(latLng, 'Current Location');
          await _getAddressFromCoordinates(latLng, 'Current Location');
        } else {
          _useDefaultLocation();
        }
      } else if (permission.isPermanentlyDenied) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permission is permanently denied. Please enable it in app settings.',
        );
        _useDefaultLocation();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permission denied. Using default location.',
        );
        _useDefaultLocation();
      }
    } catch (e) {
      print('Error getting current location: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get location: ${e.toString()}',
      );
      _useDefaultLocation();
    }
  }

  // Public method to request location permission again
  Future<void> requestLocationPermission() async {
    await _getCurrentLocation();
  }

  void _useDefaultLocation() {
    state = state.copyWith(
      currentPosition: _defaultLocation,
      selectedPosition: _defaultLocation,
      isLoading: false,
    );
    _addMarker(_defaultLocation, 'Current Location (Delhi)');
    _getAddressFromCoordinates(_defaultLocation, 'Current Location (Delhi)');
  }

  void _addMarker(LatLng position, String title) {
    final markers = <Marker>{
      Marker(
        markerId: MarkerId(title),
        position: position,
        infoWindow: InfoWindow(
          title: title,
          snippet: state.addressDetails.isNotEmpty 
              ? _getSimplifiedAddress(state.addressDetails)
              : 'Loading address...',
        ),
      ),
    };
    
    state = state.copyWith(markers: markers);
  }

  void _updateMarkerInfo(LatLng position, String title) {
    final markers = <Marker>{
      Marker(
        markerId: MarkerId(title),
        position: position,
        infoWindow: InfoWindow(
          title: title,
          snippet: _getSimplifiedAddress(state.addressDetails),
        ),
      ),
    };
    
    state = state.copyWith(markers: markers);
  }

  // Simplify address display - remove unnecessary parts
  String _getSimplifiedAddress(Map<String, String> addressDetails) {
    final address = addressDetails['address'] ?? '';
    final city = addressDetails['city'] ?? '';
    final state = addressDetails['state'] ?? '';
    
    // If address contains "Model Town", extract relevant parts and remove Pakistan references
    if (address.toLowerCase().contains('model town')) {
      final parts = address.split(',');
      final relevantParts = <String>[];
      
      for (final part in parts) {
        final trimmed = part.trim();
        // Skip parts that contain Pakistan or Lahore
        if (trimmed.toLowerCase().contains('pakistan') || 
            trimmed.toLowerCase().contains('lahore')) {
          continue;
        }
        
        if (trimmed.toLowerCase().contains('model town') || 
            trimmed.toLowerCase().contains('phase') ||
            trimmed.toLowerCase().contains('pocket')) {
          relevantParts.add(trimmed);
        }
      }
      
      if (relevantParts.isNotEmpty) {
        return '${relevantParts.join(', ')}, $city, $state';
      }
    }
    
    // For other addresses, clean up and return
    String cleanAddress = address;
    // Remove Pakistan/Lahore references from any address
    cleanAddress = cleanAddress.replaceAll(RegExp(r',?\s*(Lahore|Pakistan).*', caseSensitive: false), '');
    
    return cleanAddress.isNotEmpty ? '$cleanAddress, $city, $state' : 'Address not found';
  }

  Future<void> _getAddressFromCoordinates(LatLng position, [String? title]) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${ApiConfig.googlePlacesApiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final addressComponents = result['address_components'];
          
          Map<String, String> addressData = {
            'address': '',
            'state': '',
            'city': '',
            'landmark': '',
            'pincode': '',
          };
          
          // Parse address components
          for (var component in addressComponents) {
            final types = component['types'];
            final longName = component['long_name'];
            
            if (types.contains('street_number') || types.contains('route')) {
              addressData['address'] = addressData['address']?.isEmpty == true 
                  ? longName 
                  : '${addressData['address']}, $longName';
            } else if (types.contains('administrative_area_level_1')) {
              addressData['state'] = longName;
            } else if (types.contains('locality') || types.contains('administrative_area_level_2')) {
              addressData['city'] = longName;
            } else if (types.contains('postal_code')) {
              addressData['pincode'] = longName;
            } else if (types.contains('point_of_interest') || types.contains('establishment')) {
              addressData['landmark'] = longName;
            }
          }
          
          // If no specific address found, use formatted address
          if (addressData['address']?.isEmpty == true) {
            addressData['address'] = result['formatted_address'] ?? '';
          }
          
          state = state.copyWith(addressDetails: addressData);
          
          // Update marker info window with the fetched address
          if (title != null) {
            _updateMarkerInfo(position, title);
          }
        }
      }
    } catch (e) {
      print('Error getting address: $e');
      // Fallback to coordinates
      state = state.copyWith(
        addressDetails: {
          'address': '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          'state': '',
          'city': '',
          'landmark': '',
          'pincode': '',
        },
      );
      
      // Update marker info window with coordinates as fallback
      if (title != null) {
        _updateMarkerInfo(position, title);
      }
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        searchSuggestions: [],
        isSearching: false,
        searchQuery: query,
      );
      return;
    }

    // Only search if query has at least 2 characters
    if (query.length < 2) {
      state = state.copyWith(
        searchSuggestions: [],
        isSearching: false,
        searchQuery: query,
      );
      return;
    }

    state = state.copyWith(
      isSearching: true,
      searchQuery: query,
    );

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedQuery&key=${ApiConfig.googlePlacesApiKey}&components=country:in&types=geocode';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          List<Map<String, dynamic>> suggestions = [];
          for (var prediction in data['predictions']) {
            suggestions.add({
              'place_id': prediction['place_id'],
              'description': prediction['description'],
              'main_text': prediction['structured_formatting']?['main_text'] ?? prediction['description'],
              'secondary_text': prediction['structured_formatting']?['secondary_text'],
            });
          }

          state = state.copyWith(
            searchSuggestions: suggestions,
            isSearching: false,
          );
        } else {
          state = state.copyWith(
            searchSuggestions: [],
            isSearching: false,
          );
        }
      } else {
        state = state.copyWith(
          searchSuggestions: [],
          isSearching: false,
        );
      }
    } catch (e) {
      print('Error searching places: $e');
      state = state.copyWith(
        searchSuggestions: [],
        isSearching: false,
      );
    }
  }

  Future<void> selectPlace(Map<String, dynamic> place) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=${place['place_id']}&key=${ApiConfig.googlePlacesApiKey}&fields=geometry,formatted_address,address_components';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final latLng = LatLng(location['lat'], location['lng']);

          // Parse address components
          final addressComponents = result['address_components'];
          Map<String, String> addressData = {
            'address': '',
            'state': '',
            'city': '',
            'landmark': '',
            'pincode': '',
          };

          for (var component in addressComponents) {
            final types = component['types'];
            final longName = component['long_name'];

            if (types.contains('street_number') || types.contains('route')) {
              addressData['address'] = addressData['address']?.isEmpty == true
                  ? longName
                  : '${addressData['address']}, $longName';
            } else if (types.contains('administrative_area_level_1')) {
              addressData['state'] = longName;
            } else if (types.contains('locality') || types.contains('administrative_area_level_2')) {
              addressData['city'] = longName;
            } else if (types.contains('postal_code')) {
              addressData['pincode'] = longName;
            } else if (types.contains('point_of_interest') || types.contains('establishment')) {
              addressData['landmark'] = longName;
            }
          }

          // If no specific address found, use formatted address
          if (addressData['address']?.isEmpty == true) {
            addressData['address'] = result['formatted_address'] ?? '';
          }

          state = state.copyWith(
            currentPosition: latLng, // Update current position to the searched location
            selectedPosition: latLng,
            addressDetails: addressData,
            searchSuggestions: [],
            isSearching: false,
            searchQuery: place['description'],
          );

          _addMarker(latLng, 'Selected Location');

          // Move camera to selected location
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  void onMapTapped(LatLng position) {
    state = state.copyWith(selectedPosition: position);
    _addMarker(position, 'Selected Location');
    _getAddressFromCoordinates(position, 'Selected Location');
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void onCameraMove(CameraPosition position) {
    state = state.copyWith(selectedPosition: position.target);
  }

  void useCurrentLocation() {
    if (state.currentPosition != null) {
      state = state.copyWith(selectedPosition: state.currentPosition);
      _addMarker(state.currentPosition!, 'Current Location');
      _getAddressFromCoordinates(state.currentPosition!, 'Current Location');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> saveLocation() async
  {
    print('🗺️ [LocationProvider] Starting saveLocation...');
    print('📍 [LocationProvider] Selected position: ${state.selectedPosition}');
    print('📋 [LocationProvider] Address details: ${state.addressDetails}');

    if (state.selectedPosition == null || state.addressDetails.isEmpty) {
      print('❌ [LocationProvider] No location selected or address details empty');
      return left(const ServerFailure('No location selected', 400));
    }

    state = state.copyWith(isSaving: true, error: null);
    print('⏳ [LocationProvider] Set isSaving to true');

    try {
      print('📤 [LocationProvider] Calling UserService.setDefaultAddress...');
      final result = await _userService.setDefaultAddress(
        address: state.addressDetails['address'] ?? '',
        state: state.addressDetails['state'] ?? '',
        city: state.addressDetails['city'] ?? '',
        landmark: state.addressDetails['landmark'] ?? '',
        pincode: state.addressDetails['pincode'] ?? '',
      );

      state = state.copyWith(isSaving: false);
      print('✅ [LocationProvider] Set isSaving to false');

      // If successful, set user data in auth provider
      result.fold(
        (failure) {
          print('❌ [LocationProvider] API call failed: ${failure.message}');
          // Error handling is done by the caller
        },
        (data) {
          print('✅ [LocationProvider] API call successful');
          print('📊 [LocationProvider] Response data: $data');

          if (data['status'] == true && data['data'] != null) {
            final userData = data['data'];
            print('👤 [LocationProvider] Setting user data in auth provider');
            _ref.read(authProvider.notifier).setUserData(
              userData['userid'],
              userData['token'],
            );
            print('✅ [LocationProvider] User data set successfully');
          } else {
            print('❌ [LocationProvider] Response status is false or data is null');
          }
        },
      );

      return result;
    } catch (e) {
      print('❌ [LocationProvider] Exception occurred: $e');
      print('❌ [LocationProvider] Exception type: ${e.runtimeType}');

      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return left(UnknownFailure(e.toString()));
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSearch() {
    state = state.copyWith(
      searchSuggestions: [],
      searchQuery: '',
    );
  }
}

// Providers
final userServiceProvider = Provider<UserService>((ref) {
  // This will be injected from the main app
  throw UnimplementedError('UserService must be provided');
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final userService = ref.watch(userServiceProvider);
  return LocationNotifier(userService, ref);
});
