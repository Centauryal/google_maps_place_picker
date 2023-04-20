import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle body2RegularTextStyle(BuildContext context, Color color) {
  return GoogleFonts.poppins(
      textStyle: Theme.of(context)
          .textTheme
          .bodyText2!
          .copyWith(leadingDistribution: TextLeadingDistribution.even),
      fontSize: 14,
      color: color,
      fontWeight: FontWeight.normal,
      height: 20 / 14,
      letterSpacing: 0);
}
