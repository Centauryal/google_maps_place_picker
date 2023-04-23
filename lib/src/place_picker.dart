import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:google_maps_place_picker/providers/place_provider.dart';
import 'package:google_maps_place_picker/src/autocomplete_search.dart';
import 'package:google_maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:google_maps_place_picker/src/google_map_place_picker.dart';
import 'package:google_maps_place_picker/src/utils/show_snackbar.dart';
import 'package:google_maps_place_picker/src/utils/uuid.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

enum PinState { Preparing, Idle, Dragging }

enum SearchingState { Idle, Searching }

class PlacePicker extends StatefulWidget {
  PlacePicker({
    Key? key,
    required this.apiKey,
    this.onPlacePicked,
    required this.initialPosition,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    // this.searchBarHeight,
    // this.contentPadding,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceAndroidLocationManager = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.errorMessageGpsIsDisable = '',
    this.defaultResultPinPointNotFound,
    this.placeIdFromSearch,
  })  : useAutoCompleteSearch = false,
        prefixIconData = null,
        suffixIconData = null,
        onPickedSearch = null,
        super(key: key);

  PlacePicker.autoCompleteSearch({
    Key? key,
    required this.apiKey,
    this.onPlacePicked,
    required this.initialPosition,
    required this.onPickedSearch,
    this.useCurrentLocation,
    this.desiredLocationAccuracy = LocationAccuracy.high,
    this.onMapCreated,
    this.hintText,
    this.searchingText,
    // this.searchBarHeight,
    // this.contentPadding,
    this.onAutoCompleteFailed,
    this.onGeocodingSearchFailed,
    this.proxyBaseUrl,
    this.httpClient,
    this.selectedPlaceWidgetBuilder,
    this.pinBuilder,
    this.autoCompleteDebounceInMilliseconds = 500,
    this.cameraMoveDebounceInMilliseconds = 750,
    this.initialMapType = MapType.normal,
    this.enableMapTypeButton = true,
    this.enableMyLocationButton = true,
    this.myLocationButtonCooldown = 10,
    this.usePinPointingSearch = true,
    this.usePlaceDetailSearch = false,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.selectInitialPosition = false,
    this.resizeToAvoidBottomInset = true,
    this.initialSearchString,
    this.searchForInitialValue = false,
    this.forceAndroidLocationManager = false,
    this.forceSearchOnZoomChanged = false,
    this.automaticallyImplyAppBarLeading = true,
    this.autocompleteOnTrailingWhitespace = false,
    this.hidePlaceDetailsWhenDraggingPin = true,
    this.errorMessageGpsIsDisable = '',
    this.defaultResultPinPointNotFound,
    this.prefixIconData,
    this.suffixIconData,
  })  : useAutoCompleteSearch = true,
        placeIdFromSearch = null,
        super(key: key);

  final String apiKey;

  final LatLng initialPosition;
  final bool? useCurrentLocation;
  final LocationAccuracy desiredLocationAccuracy;

  final MapCreatedCallback? onMapCreated;

  final String? hintText;
  final String? searchingText;

  // final double searchBarHeight;
  // final EdgeInsetsGeometry contentPadding;

  final ValueChanged<String>? onAutoCompleteFailed;
  final ValueChanged<String>? onGeocodingSearchFailed;
  final int autoCompleteDebounceInMilliseconds;
  final int cameraMoveDebounceInMilliseconds;

  final MapType initialMapType;
  final bool enableMapTypeButton;
  final bool enableMyLocationButton;
  final int myLocationButtonCooldown;

  final bool usePinPointingSearch;
  final bool usePlaceDetailSearch;
  final bool useAutoCompleteSearch;

  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;

  /// If true the [body] and the scaffold's floating widgets should size
  /// themselves to avoid the onscreen keyboard whose height is defined by the
  /// ambient [MediaQuery]'s [MediaQueryData.viewInsets] `bottom` property.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomInset;

  final bool selectInitialPosition;

  /// By using default setting of Place Picker, it will result result when user hits the select here button.
  ///
  /// If you managed to use your own [selectedPlaceWidgetBuilder], then this WILL NOT be invoked, and you need use data which is
  /// being sent with [selectedPlaceWidgetBuilder].
  final ValueChanged<PickResult>? onPlacePicked;

  /// optional - builds selected place's UI
  ///
  /// It is provided by default if you leave it as a null.
  /// INPORTANT: If this is non-null, [onPlacePicked] will not be invoked, as there will be no default 'Select here' button.
  final SelectedPlaceWidgetBuilder? selectedPlaceWidgetBuilder;

  /// optional - builds customized pin widget which indicates current pointing position.
  ///
  /// It is provided by default if you leave it as a null.
  final PinBuilder? pinBuilder;

  /// optional - sets 'proxy' value in google_maps_webservice
  ///
  /// In case of using a proxy the baseUrl can be set.
  /// The apiKey is not required in case the proxy sets it.
  /// (Not storing the apiKey in the app is good practice)
  final String? proxyBaseUrl;

  /// optional - set 'client' value in google_maps_webservice
  ///
  /// In case of using a proxy url that requires authentication
  /// or custom configuration
  final BaseClient? httpClient;

  /// Initial value of autocomplete search
  final String? initialSearchString;

  /// Whether to search for the initial value or not
  final bool searchForInitialValue;

  /// On Android devices you can set [forceAndroidLocationManager]
  /// to true to force the plugin to use the [LocationManager] to determine the
  /// position instead of the [FusedLocationProviderClient]. On iOS this is ignored.
  final bool forceAndroidLocationManager;

  /// Allow searching place when zoom has changed. By default searching is disabled when zoom has changed in order to prevent unwilling API usage.
  final bool forceSearchOnZoomChanged;

  /// Whether to display appbar backbutton. Defaults to true.
  final bool automaticallyImplyAppBarLeading;

  /// Will perform an autocomplete search, if set to true. Note that setting
  /// this to true, while providing a smoother UX experience, may cause
  /// additional unnecessary queries to the Places API.
  ///
  /// Defaults to false.
  final bool autocompleteOnTrailingWhitespace;

  final bool hidePlaceDetailsWhenDraggingPin;

  final String errorMessageGpsIsDisable;

  /// The widget bottom is used for pin point results
  final Widget? defaultResultPinPointNotFound;

  /// The widget Autocomplete Search Bar
  final IconData? prefixIconData;
  final IconData? suffixIconData;

  /// By using the default settings of the autocomplete search,
  /// results will appear when the user types the location he is looking for.
  final ValueChanged<String>? onPickedSearch;

  /// PlaceId results from autocomplete search, can only be used when using a map
  final String? placeIdFromSearch;

  @override
  _PlacePickerState createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  GlobalKey appBarKey = GlobalKey();
  Future<PlaceProvider>? _futureProvider;
  PlaceProvider? provider;
  late SearchBarController searchBarController;

  @override
  void initState() {
    super.initState();
    if (widget.useAutoCompleteSearch) {
      searchBarController = SearchBarController();
    }

    _futureProvider = _initPlaceProvider();
  }

  @override
  void dispose() {
    if (widget.useAutoCompleteSearch) {
      searchBarController.dispose();
    }

    super.dispose();
  }

  Future<PlaceProvider> _initPlaceProvider() async {
    final headers = await GoogleApiHeaders().getHeaders();
    final provider = PlaceProvider(
      widget.apiKey,
      widget.proxyBaseUrl,
      widget.httpClient,
      headers,
    );
    provider.sessionToken = Uuid().generateV4();
    provider.desiredAccuracy = widget.desiredLocationAccuracy;
    provider.setMapType(widget.initialMapType);

    return provider;
  }

  @override
  Widget build(BuildContext context) {
    final useOnlySearch = widget.useAutoCompleteSearch;
    return WillPopScope(
      onWillPop: () {
        if (widget.useAutoCompleteSearch) {
          searchBarController.clearOverlay();
        }
        return Future.value(true);
      },
      child: FutureBuilder<PlaceProvider>(
        future: _futureProvider,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            provider = snapshot.data;
            final isPlaceIdNotNull = widget.placeIdFromSearch != null &&
                widget.placeIdFromSearch?.isNotEmpty == true;
            if (isPlaceIdNotNull) {
              _pickPrediction(widget.placeIdFromSearch);
            }

            return MultiProvider(
              providers: [
                ChangeNotifierProvider<PlaceProvider>.value(value: provider!),
              ],
              child: useOnlySearch
                  ? _buildSearchBar(context)
                  : Scaffold(
                      key: ValueKey<int>(provider.hashCode),
                      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
                      extendBodyBehindAppBar: true,
                      appBar: AppBar(
                        key: appBarKey,
                        automaticallyImplyLeading: false,
                        iconTheme: Theme.of(context).iconTheme,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        titleSpacing: 0.0,
                        title: _buildAppBar(context),
                      ),
                      body: _buildMapWithLocation(),
                    ),
            );
          }

          final children = <Widget>[];
          if (snapshot.hasError) {
            children.addAll([
              Icon(
                Icons.error_outline,
                color: Theme.of(context).errorColor,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ]);
          } else {
            children.add(CircularProgressIndicator());
          }

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 16),
        widget.automaticallyImplyAppBarLeading
            ? SizedBox.square(
                dimension: 48,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Center(
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.keyboard_arrow_left,
                        color: Colors.black,
                        size: 36,
                      ),
                      color: Colors.white,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                ),
              )
            : SizedBox(),
        if (widget.useAutoCompleteSearch)
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Expanded(
              child: AutoCompleteSearch(
                  appBarKey: appBarKey,
                  searchBarController: searchBarController,
                  sessionToken: provider!.sessionToken,
                  hintText: widget.hintText,
                  searchingText: widget.searchingText,
                  debounceMilliseconds:
                      widget.autoCompleteDebounceInMilliseconds,
                  onPicked: (prediction) {
                    _pickPrediction(prediction.placeId);
                  },
                  onSearchFailed: (status) {
                    if (widget.onAutoCompleteFailed != null) {
                      widget.onAutoCompleteFailed!(status);
                    }
                  },
                  autocompleteOffset: widget.autocompleteOffset,
                  autocompleteRadius: widget.autocompleteRadius,
                  autocompleteLanguage: widget.autocompleteLanguage,
                  autocompleteComponents: widget.autocompleteComponents,
                  autocompleteTypes: widget.autocompleteTypes,
                  strictbounds: widget.strictbounds,
                  region: widget.region,
                  initialSearchString: widget.initialSearchString,
                  searchForInitialValue: widget.searchForInitialValue,
                  autocompleteOnTrailingWhitespace:
                      widget.autocompleteOnTrailingWhitespace),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: AutoCompleteSearch(
        appBarKey: appBarKey,
        searchBarController: searchBarController,
        sessionToken: provider!.sessionToken,
        hintText: widget.hintText,
        searchingText: widget.searchingText,
        debounceMilliseconds: widget.autoCompleteDebounceInMilliseconds,
        onPicked: (prediction) {
          if (widget.useAutoCompleteSearch) {
            widget.onPickedSearch!(prediction.placeId ?? '');
          } else {
            _pickPrediction(prediction.placeId);
          }
        },
        onSearchFailed: (status) {
          if (widget.onAutoCompleteFailed != null) {
            widget.onAutoCompleteFailed!(status);
          }
        },
        autocompleteOffset: widget.autocompleteOffset,
        autocompleteRadius: widget.autocompleteRadius,
        autocompleteLanguage: widget.autocompleteLanguage,
        autocompleteComponents: widget.autocompleteComponents,
        autocompleteTypes: widget.autocompleteTypes,
        strictbounds: widget.strictbounds,
        region: widget.region,
        initialSearchString: widget.initialSearchString,
        searchForInitialValue: widget.searchForInitialValue,
        autocompleteOnTrailingWhitespace:
            widget.autocompleteOnTrailingWhitespace,
        prefixIconData: widget.prefixIconData,
        suffixIconData: widget.suffixIconData,
        onTapMyLocation: () async => await myLocationPermission(),
      ),
    );
  }

  _pickPrediction(String? predictionPlaceId) async {
    provider!.placeSearchingState = SearchingState.Searching;

    final PlacesDetailsResponse response =
        await provider!.places.getDetailsByPlaceId(
      predictionPlaceId ?? '',
      sessionToken: provider!.sessionToken,
      language: widget.autocompleteLanguage,
    );

    if (response.errorMessage?.isNotEmpty == true ||
        response.status == "REQUEST_DENIED") {
      if (widget.onAutoCompleteFailed != null) {
        widget.onAutoCompleteFailed!(response.status);
      }
      return;
    }

    provider!.selectedPlace = PickResult.fromPlaceDetailResult(response.result);

    // Prevents searching again by camera movement.
    provider!.isAutoCompleteSearching = true;

    await _moveTo(provider!.selectedPlace!.geometry!.location.lat,
        provider!.selectedPlace!.geometry!.location.lng);

    provider!.placeSearchingState = SearchingState.Idle;
  }

  _moveTo(double latitude, double longitude) async {
    GoogleMapController? controller = provider!.mapController;
    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 16,
        ),
      ),
    );
  }

  _moveToCurrentPosition() async {
    if (provider!.currentPosition != null) {
      await _moveTo(provider!.currentPosition!.latitude,
          provider!.currentPosition!.longitude);
    }
  }

  Widget _buildMapWithLocation() {
    if (widget.useCurrentLocation != null && widget.useCurrentLocation!) {
      return FutureBuilder(
          future: provider!
              .updateCurrentLocation(widget.forceAndroidLocationManager),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              if (provider!.currentPosition == null) {
                return _buildMap(widget.initialPosition);
              } else {
                return _buildMap(LatLng(provider!.currentPosition!.latitude,
                    provider!.currentPosition!.longitude));
              }
            }
          });
    } else {
      return FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 1)),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return _buildMap(widget.initialPosition);
          }
        },
      );
    }
  }

  Widget _buildMap(LatLng initialTarget) {
    return GoogleMapPlacePicker(
      initialTarget: initialTarget,
      appBarKey: appBarKey,
      selectedPlaceWidgetBuilder: widget.selectedPlaceWidgetBuilder,
      pinBuilder: widget.pinBuilder,
      onSearchFailed: widget.onGeocodingSearchFailed,
      debounceMilliseconds: widget.cameraMoveDebounceInMilliseconds,
      enableMapTypeButton: widget.enableMapTypeButton,
      enableMyLocationButton: widget.enableMyLocationButton,
      usePinPointingSearch: widget.usePinPointingSearch,
      usePlaceDetailSearch: widget.usePlaceDetailSearch,
      onMapCreated: widget.onMapCreated,
      selectInitialPosition: widget.selectInitialPosition,
      language: widget.autocompleteLanguage,
      forceSearchOnZoomChanged: widget.forceSearchOnZoomChanged,
      hidePlaceDetailsWhenDraggingPin: widget.hidePlaceDetailsWhenDraggingPin,
      defaultResultPinPointNotFound: widget.defaultResultPinPointNotFound,
      onToggleMapType: () {
        provider!.switchMapType();
      },
      onMyLocation: () async => await myLocationPermission(),
      onMoveStart: () {
        if (widget.useAutoCompleteSearch) {
          searchBarController.reset();
        }
      },
      onPlacePicked: widget.onPlacePicked,
    );
  }

  Future<void> myLocationPermission() async {
    await Permission.location.request();
    if (await Permission.location.request().isGranted) {
      // Prevent to click many times in short period.
      if (provider!.isOnUpdateLocationCooldown == false) {
        provider!.isOnUpdateLocationCooldown = true;
        Timer(Duration(seconds: widget.myLocationButtonCooldown), () {
          provider!.isOnUpdateLocationCooldown = false;
        });
        await provider!
            .updateCurrentLocation(widget.forceAndroidLocationManager);
        await _moveToCurrentPosition();
      }
    } else {
      showSnackBar(context, widget.errorMessageGpsIsDisable);
    }
  }
}
