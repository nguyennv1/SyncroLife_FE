import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import '../theme/colors.dart';

Widget buildWebSignInButton({
  required Future<void>? initializationFuture,
  required bool isInitialized,
}) {
  return FutureBuilder<void>(
    future: initializationFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done && isInitialized) {
        try {
          return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(
            configuration: web.GSIButtonConfiguration(
              theme: web.GSIButtonTheme.outline,
              shape: web.GSIButtonShape.rectangular,
              size: web.GSIButtonSize.large,
              text: web.GSIButtonText.continueWith,
            ),
          );
        } catch (e) {
          return Center(child: Text("Error loading Google button", style: TextStyle(color: Colors.red)));
        }
      }
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
        ),
      );
    },
  );
}
