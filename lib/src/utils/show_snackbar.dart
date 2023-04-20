import 'package:flutter/material.dart';

import 'text_style.dart';

void showSnackBar(BuildContext context, String errorGpsDisable) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    duration: Duration(milliseconds: 4000),
    padding: EdgeInsets.zero,
    margin: EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 20.65,
    ),
    shape: const RoundedRectangleBorder(),
    content: Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            offset: Offset(0.0, 4),
            blurRadius: 16,
            spreadRadius: 0.0,
            color: Colors.black.withOpacity(0.24),
          )
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          errorGpsDisable,
          style: body2RegularTextStyle(context, Colors.white),
        ),
      ),
    ),
  ));
}
