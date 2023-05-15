import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:google_maps_place_picker/providers/place_provider.dart';
import 'package:google_maps_place_picker/providers/search_provider.dart';
import 'package:google_maps_place_picker/src/components/prediction_tile.dart';
import 'package:google_maps_place_picker/src/controllers/autocomplete_search_controller.dart';
import 'package:google_maps_place_picker/src/utils/text_style.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

class AutoCompleteSearch extends StatefulWidget {
  const AutoCompleteSearch({
    Key? key,
    required this.sessionToken,
    required this.onPicked,
    required this.appBarKey,
    this.hintText,
    this.contentPadding,
    this.debounceMilliseconds,
    this.onSearchFailed,
    required this.searchBarController,
    this.autocompleteOffset,
    this.autocompleteRadius,
    this.autocompleteLanguage,
    this.autocompleteComponents,
    this.autocompleteTypes,
    this.strictbounds,
    this.region,
    this.initialSearchString,
    this.searchForInitialValue,
    this.autocompleteOnTrailingWhitespace,
    this.onTapMyLocation,
    this.prefixIconData,
    this.suffixIconData,
  }) : super(key: key);

  final String? sessionToken;
  final String? hintText;
  final EdgeInsetsGeometry? contentPadding;
  final int? debounceMilliseconds;
  final ValueChanged<Prediction> onPicked;
  final ValueChanged<String>? onSearchFailed;
  final SearchBarController searchBarController;
  final num? autocompleteOffset;
  final num? autocompleteRadius;
  final String? autocompleteLanguage;
  final List<String>? autocompleteTypes;
  final List<Component>? autocompleteComponents;
  final bool? strictbounds;
  final String? region;
  final GlobalKey appBarKey;
  final String? initialSearchString;
  final bool? searchForInitialValue;
  final bool? autocompleteOnTrailingWhitespace;
  final VoidCallback? onTapMyLocation;
  final IconData? prefixIconData;
  final IconData? suffixIconData;

  @override
  AutoCompleteSearchState createState() => AutoCompleteSearchState();
}

class AutoCompleteSearchState extends State<AutoCompleteSearch> {
  TextEditingController controller = TextEditingController();
  FocusNode focus = FocusNode();
  OverlayEntry? overlayEntry;
  SearchProvider provider = SearchProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchString != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.text = widget.initialSearchString!;
        if (widget.searchForInitialValue!) {
          _onSearchInputChange();
        }
      });
    }
    controller.addListener(_onSearchInputChange);
    focus.addListener(_onFocusChanged);

    widget.searchBarController.attach(this);
  }

  @override
  void dispose() {
    controller.removeListener(_onSearchInputChange);
    controller.dispose();

    focus.removeListener(_onFocusChanged);
    focus.dispose();
    _clearOverlay();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: _buildSearchBarText(),
    );
  }

  static OutlineInputBorder _enabledBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          width: 1,
          color: Color(0xFF999999),
        ),
      );

  static OutlineInputBorder _focusedBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          width: 2,
          color: Color(0xFF12784A),
        ),
      );

  Widget _buildSearchTextField(String data) {
    return TextField(
      key: widget.appBarKey,
      textInputAction: TextInputAction.search,
      controller: controller,
      focusNode: focus,
      textCapitalization: TextCapitalization.sentences,
      style: body2RegularTextStyle(context, Color(0xE6000000)),
      decoration: InputDecoration(
        isDense: true,
        fillColor: Colors.white,
        filled: true,
        hintText: widget.hintText,
        hintStyle: body2RegularTextStyle(context, Color(0x4D000000)),
        border: InputBorder.none,
        contentPadding: widget.contentPadding ?? EdgeInsets.all(16),
        enabledBorder: _enabledBorder(),
        focusedBorder: _focusedBorder(),
        prefixIconConstraints: BoxConstraints.tight(
          Size(44, 24),
        ),
        prefixIcon: Icon(
          widget.prefixIconData ?? Icons.search,
          color: Color(0xFF999999),
          size: 24,
        ),
        suffixIconConstraints: BoxConstraints.tight(
          Size(44, 24),
        ),
        suffixIcon: data.length > 0 && focus.hasFocus
            ? Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  customBorder: const CircleBorder(),
                  onTap: () {
                    clearText();
                  },
                  child: Icon(
                    widget.suffixIconData ?? Icons.clear,
                    color: Color(0xFF999999),
                    size: 24,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSearchBarText() {
    return Selector<SearchProvider, String>(
        selector: (_, provider) => provider.searchTerm,
        builder: (_, data, __) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                _buildSearchTextField(data),
                SizedBox(height: 8),
                if (data.length < 3) _buildMyCurrentLocationText(),
              ],
            ),
          );
        });
  }

  Widget _buildMyCurrentLocationText() {
    return GestureDetector(
      onTap: widget.onTapMyLocation,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1, color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.gps_fixed_outlined, size: 24),
              ),
            ),
            Expanded(
              child: Text(
                'Use your current location',
                style: body2RegularTextStyle(context, Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onSearchInputChange() {
    if (!mounted) return;
    this.provider.searchTerm = controller.text;

    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (controller.text.isEmpty) {
      provider.debounceTimer?.cancel();
      _searchPlace(controller.text);
      return;
    }

    if (controller.text.trim() == this.provider.prevSearchTerm.trim()) {
      provider.debounceTimer?.cancel();
      return;
    }

    if (!widget.autocompleteOnTrailingWhitespace! &&
        controller.text.substring(controller.text.length - 1) == " ") {
      provider.debounceTimer?.cancel();
      return;
    }

    if (provider.debounceTimer?.isActive ?? false) {
      provider.debounceTimer!.cancel();
    }

    provider.debounceTimer =
        Timer(Duration(milliseconds: widget.debounceMilliseconds!), () {
      _searchPlace(controller.text.trim());
    });
  }

  _onFocusChanged() {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);
    provider.isSearchBarFocused = focus.hasFocus;
    provider.debounceTimer?.cancel();
    provider.placeSearchingState = SearchingState.Idle;
  }

  _searchPlace(String searchTerm) {
    this.provider.prevSearchTerm = searchTerm;

    _clearOverlay();

    if (searchTerm.length < 3) return;

    _performAutoCompleteSearch(searchTerm);
  }

  _clearOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  _displayOverlay(Widget overlayChild) {
    _clearOverlay();

    final appBarRenderBox =
        widget.appBarKey.currentContext?.findRenderObject() as RenderBox;
    final size = appBarRenderBox.size;
    final offset = appBarRenderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        height: MediaQuery.of(context).size.height,
        top: offset.dy + size.height + 16,
        left: offset.dx,
        right: offset.dx,
        child: Material(
          elevation: 4.0,
          child: overlayChild,
        ),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry!);
  }

  Widget _buildPredictionOverlay(List<Prediction> predictions) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        physics: const FixedExtentScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: predictions.length,
        itemBuilder: (_, index) {
          return PredictionTile(
            prediction: predictions[index],
            onTap: (selectedPrediction) {
              resetSearchBar();
              widget.onPicked(selectedPrediction);
            },
          );
        },
      ),
    );
  }

  _performAutoCompleteSearch(String searchTerm) async {
    PlaceProvider provider = PlaceProvider.of(context, listen: false);

    if (searchTerm.isNotEmpty) {
      final PlacesAutocompleteResponse response =
          await provider.places.autocomplete(
        searchTerm,
        sessionToken: widget.sessionToken,
        location: provider.currentPosition == null
            ? null
            : Location(
                lat: provider.currentPosition!.latitude,
                lng: provider.currentPosition!.longitude),
        offset: widget.autocompleteOffset,
        radius: widget.autocompleteRadius,
        language: widget.autocompleteLanguage,
        types: widget.autocompleteTypes ?? const [],
        components: widget.autocompleteComponents ?? const [],
        strictbounds: widget.strictbounds ?? false,
        region: widget.region,
      );

      if (response.errorMessage?.isNotEmpty == true ||
          response.status == "REQUEST_DENIED") {
        if (widget.onSearchFailed != null) {
          widget.onSearchFailed!(response.status);
        }
        return;
      }

      _displayOverlay(_buildPredictionOverlay(response.predictions));
    }
  }

  clearText() {
    provider.searchTerm = "";
    controller.clear();
  }

  resetSearchBar() {
    clearText();
    focus.unfocus();
  }

  clearOverlay() {
    _clearOverlay();
  }
}
