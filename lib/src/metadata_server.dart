// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import './common.dart';

Future<AccessCredentials> obtainAccessCredentialsViaMetadataServerFix(
    http.Client baseClient) {
  return new MetadataServerAuthorizationFlowFix(baseClient).run();
}

class MetadataServerAuthorizationFlowFix {
  static const _headers = const {'Metadata-Flavor': 'Google'};
  static const _SERVICE_ACCOUNT_URL_PREFIX =
      'http://metadata/computeMetadata/v1/instance/service-accounts';

  final String email;
  final Uri _tokenUrl;
  final http.Client _client;

  factory MetadataServerAuthorizationFlowFix(http.Client client,
      {String email: 'default'}) {
    var encodedEmail = Uri.encodeComponent(email);
    var tokenUrl =
        Uri.parse('$_SERVICE_ACCOUNT_URL_PREFIX/$encodedEmail/token');
    return new MetadataServerAuthorizationFlowFix._(client, email, tokenUrl);
  }

  MetadataServerAuthorizationFlowFix._(this._client, this.email, this._tokenUrl);

  Future<AccessCredentials> run() async {
    Future<Map> tokenFuture = _getToken();

    var json = await tokenFuture;

    var type = json['token_type'];
    var accessToken = json['access_token'];
    var expiresIn = json['expires_in'];
    var error = json['error'];

    if (error != null) {
      throw new Exception('Error while obtaining credentials from metadata '
          'server. Error message: $error.');
    }

    if (type != 'Bearer' || accessToken == null || expiresIn is! int) {
      throw new Exception('Invalid response from metadata server.');
    }

    return new AccessCredentials(
        new AccessToken(type, accessToken, expiryDate(expiresIn)), null, []);
  }

  Future<Map> _getToken() {
    return _client.get(_tokenUrl, headers: _headers).then((response) {
      return JSON.decode(response.body);
    });
  }
}
