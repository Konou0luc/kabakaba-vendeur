import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Pas de proxy système (c'est lui qui envoyait le trafic sur le port 45178).
/// Pas de `connectionFactory` : imposer le premier A de Vercel rate souvent
/// depuis l'Afrique de l'Ouest (anycast). Le HttpClient gère le DNS lui-même.
void attachVendorHttpAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient()..idleTimeout = const Duration(seconds: 15);
      client.findProxy = (_) => 'DIRECT';
      return client;
    },
  );
}
