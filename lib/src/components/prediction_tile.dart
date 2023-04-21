import 'package:flutter/material.dart';
import 'package:google_maps_place_picker/src/utils/text_style.dart';
import 'package:google_maps_webservice/places.dart';

class PredictionTile extends StatelessWidget {
  final Prediction prediction;
  final ValueChanged<Prediction>? onTap;

  PredictionTile({required this.prediction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: prediction.structuredFormatting?.mainText != null
          ? Text(
              prediction.structuredFormatting?.mainText ?? '',
              style: body2BoldTextStyle(context, Colors.black),
            )
          : null,
      subtitle: RichText(
        text: TextSpan(
          children: _buildPredictionText(context),
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap!(prediction);
        }
      },
    );
  }

  List<TextSpan> _buildPredictionText(BuildContext context) {
    final List<TextSpan> result = <TextSpan>[];

    if (prediction.matchedSubstrings.length > 0) {
      MatchedSubstring matchedSubString = prediction.matchedSubstrings[0];
      // There is no matched string at the beginning.
      if (matchedSubString.offset > 0) {
        result.add(
          TextSpan(
            text: prediction.description
                ?.substring(0, matchedSubString.offset as int?),
            style: body2RegularTextStyle(context, Color(0x99000000)),
          ),
        );
      }

      // Matched strings.
      result.add(
        TextSpan(
          text: prediction.description?.substring(
              matchedSubString.offset as int,
              matchedSubString.offset + matchedSubString.length as int?),
          style: body2MediumTextStyle(context, Color(0x99000000)),
        ),
      );

      // Other strings.
      if (matchedSubString.offset + matchedSubString.length <
          (prediction.description?.length ?? 0)) {
        result.add(
          TextSpan(
            text: prediction.description?.substring(
                matchedSubString.offset + matchedSubString.length as int),
            style: body2RegularTextStyle(context, Color(0x99000000)),
          ),
        );
      }
      // If there is no matched strings, but there are predicts. (Not sure if this happens though)
    } else {
      result.add(
        TextSpan(
          text: prediction.description,
          style: body2RegularTextStyle(context, Color(0x99000000)),
        ),
      );
    }

    return result;
  }
}
