
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';

import 'phone_verification_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  final bool isFromProfile;
  const MapScreen({super.key, this.isFromProfile = false});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    ref.read(locationProvider.notifier).onMapCreated(controller);
  }

  void _onMapTapped(LatLng position) {
    ref.read(locationProvider.notifier).onMapTapped(position);
  }

  void _onCameraMove(CameraPosition position) {
    ref.read(locationProvider.notifier).onCameraMove(position);
  }

  void _useCurrentLocation() {
    ref.read(locationProvider.notifier).useCurrentLocation();
  }

  Future<void> _saveLocation() async {
    print('💾 [MapScreen] Save button pressed');
    print('📍 [MapScreen] Current location state:');
    print(
        '   - Selected position: ${ref.read(locationProvider).selectedPosition}');
    print('   - Address details: ${ref.read(locationProvider).addressDetails}');
    print('   - Is saving: ${ref.read(locationProvider).isSaving}');

    final result = await ref.read(locationProvider.notifier).saveLocation();

    print('📥 [MapScreen] Save result received');

    result.fold(
      (failure) {
        print('❌ [MapScreen] Save failed: ${failure.message}');
        print('❌ [MapScreen] Failure type: ${failure.runtimeType}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (success) {
        print('✅ [MapScreen] Save successful');
        print('📊 [MapScreen] Success data: $success');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to phone verification
        print('🚀 [MapScreen] Navigating to PhoneVerificationScreen');
        if (widget.isFromProfile == false) {
          Navigator.pushReplacement(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: const PhoneVerificationScreen(),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.black87),
                    ),
                    const Text(
                      'Choose Your Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Instruction text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Select the location where you want to get the service.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Search bar with autocomplete
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search location (e.g., Noida, Delhi)',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: locationState.isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(locationProvider.notifier)
                                        .clearSearch();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          ref
                              .read(locationProvider.notifier)
                              .searchPlaces(value);
                        },
                      ),
                    ),

                    // Search suggestions dropdown
                    if (locationState.searchSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: locationState.searchSuggestions.length > 5
                              ? 5
                              : locationState.searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion =
                                locationState.searchSuggestions[index];
                            return Container(
                              decoration: BoxDecoration(
                                border: index <
                                        (locationState.searchSuggestions
                                                        .length >
                                                    5
                                                ? 5
                                                : locationState
                                                    .searchSuggestions.length) -
                                            1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 0.5,
                                        ),
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.location_on,
                                    color: Color(0xFF217043)),
                                title: Text(
                                  suggestion['main_text'] ??
                                      suggestion['description'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: suggestion['secondary_text'] != null
                                    ? Text(
                                        suggestion['secondary_text'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                                dense: true,
                                onTap: () {
                                  ref
                                      .read(locationProvider.notifier)
                                      .selectPlace(suggestion);
                                  _searchController.clear();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Current Location Card - only show when not searching
              if (locationState.currentPosition != null &&
                  !locationState.isLoading &&
                  locationState.searchSuggestions.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locationState.addressDetails.isNotEmpty
                            ? _getSimplifiedAddress(
                                locationState.addressDetails)
                            : 'Loading address...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Map preview
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: locationState.currentPosition!,
                              zoom: 15,
                            ),
                            onTap: _onMapTapped,
                            markers: locationState.markers,
                            mapType: MapType.normal,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            onCameraMove: _onCameraMove,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: _useCurrentLocation,
                          child: const Text(
                            'Use Current Location',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 35),

              // Save button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton(
                  onPressed: locationState.selectedPosition != null &&
                          !locationState.isSaving
                      ? _saveLocation
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: locationState.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    cleanAddress = cleanAddress.replaceAll(
        RegExp(r',?\s*(Lahore|Pakistan).*', caseSensitive: false), '');

    return cleanAddress.isNotEmpty
        ? '$cleanAddress, $city, $state'
        : 'Address not found';
  }
}
