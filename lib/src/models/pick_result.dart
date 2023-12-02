import 'package:collection/collection.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:google_maps_webservice/places.dart';

class PickResult {
  PickResult({
    this.placeId,
    this.geometry,
    this.formattedAddress,
    this.types,
    this.addressComponents,
    this.adrAddress,
    this.formattedPhoneNumber,
    this.id,
    this.reference,
    this.icon,
    this.name,
    this.openingHours,
    this.photos,
    this.internationalPhoneNumber,
    this.priceLevel,
    this.rating,
    this.scope,
    this.url,
    this.vicinity,
    this.utcOffset,
    this.website,
    this.reviews,
  });

  final String? placeId;
  final Geometry? geometry;
  final String? formattedAddress;
  final List<String>? types;
  final List<AddressComponent>? addressComponents;

  // Below results will not be fetched if 'usePlaceDetailSearch' is set to false (Defaults to false).
  final String? adrAddress;
  final String? formattedPhoneNumber;
  final String? id;
  final String? reference;
  final String? icon;
  final String? name;
  final OpeningHoursDetail? openingHours;
  final List<Photo>? photos;
  final String? internationalPhoneNumber;
  final PriceLevel? priceLevel;
  final num? rating;
  final String? scope;
  final String? url;
  final String? vicinity;
  final num? utcOffset;
  final String? website;
  final List<Review>? reviews;

  factory PickResult.fromGeocodingResult(GeocodingResult result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
    );
  }

  factory PickResult.fromPlaceDetailResult(PlaceDetails result) {
    return PickResult(
      placeId: result.placeId,
      geometry: result.geometry,
      formattedAddress: result.formattedAddress,
      types: result.types,
      addressComponents: result.addressComponents,
      adrAddress: result.adrAddress,
      formattedPhoneNumber: result.formattedPhoneNumber,
      id: result.id,
      reference: result.reference,
      icon: result.icon,
      name: result.name,
      openingHours: result.openingHours,
      photos: result.photos,
      internationalPhoneNumber: result.internationalPhoneNumber,
      priceLevel: result.priceLevel,
      rating: result.rating,
      scope: result.scope,
      url: result.url,
      vicinity: result.vicinity,
      utcOffset: result.utcOffset,
      website: result.website,
      reviews: result.reviews,
    );
  }

  factory PickResult.fromGeocodingResultVoila(
    GeocodingResult primaryResult, {
    GeocodingResult? secondaryResult,
  }) {
    String? formattedAddress = primaryResult.formattedAddress;
    String? name;
    List<AddressComponent> addressComponent = primaryResult.addressComponents;

    // SECTION SET FORMATTED ADDRESS
    //
    // check if type [plus_code] exists in primaryResponse
    final primaryPlusCodeComponent =
        primaryResult.addressComponents.firstWhereOrNull(
      (e) => e.types.first == 'plus_code',
    );

    if (primaryPlusCodeComponent != null) {
      final plusCode = primaryPlusCodeComponent.longName;

      // Escape special characters in variables plusCode
      String escapedCharacter = RegExp.escape(plusCode);

      // Removes characters along with comma punctuation (',') and spaces after them
      String newAddressFormatted = (primaryResult.formattedAddress ?? '')
          .replaceAll(RegExp('$escapedCharacter,\\s*'), '');

      // set new address without [plus_code]
      formattedAddress = newAddressFormatted;
    }

    // SECTION SET NAME ADDRESS
    //
    // set name address based on the first character before the comma character
    name = formattedAddress?.split(',').first.trim();

    // SECTION SET ADDRESS COMPONENT
    //
    // check if type [postal_code] exists in primaryResponse
    final primaryPostalCodeComponent =
        primaryResult.addressComponents.firstWhereOrNull(
      (e) => e.types.first == 'postal_code',
    );

    // check if type [secondaryResult] is not null
    if (secondaryResult != null) {
      // check if type [postal_code] exists in secondaryResponse
      final secondaryPostalCodeComponent =
          secondaryResult.addressComponents.firstWhereOrNull(
        (e) => e.types.first == 'postal_code',
      );

      // if the [postal_code] type in [secondaryResponse] exists then it will
      // be added to the addressComponent list
      if (primaryPostalCodeComponent == null &&
          secondaryPostalCodeComponent != null) {
        addressComponent = [
          secondaryPostalCodeComponent,
          ...primaryResult.addressComponents,
        ];
      }
    }

    return PickResult(
      placeId: primaryResult.placeId,
      geometry: primaryResult.geometry,
      formattedAddress: formattedAddress,
      types: primaryResult.types,
      addressComponents: addressComponent,
      name: name,
    );
  }
}
