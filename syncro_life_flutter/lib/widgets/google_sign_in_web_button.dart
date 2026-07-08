export 'google_sign_in_web_button_stub.dart'
    if (dart.library.html) 'google_sign_in_web_button_real.dart'
    if (dart.library.js_interop) 'google_sign_in_web_button_real.dart';
