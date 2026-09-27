import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';

  static String get vendorPinHashKey =>
      dotenv.env['VENDOR_PIN_HASH_KEY'] ?? 'kabakaba_vendor_pin_salt_v1';
}
