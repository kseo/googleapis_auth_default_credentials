// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import './common.dart';

/// Represents credentials for a user.
class UserCredentials {
  /// The clientId.
  final ClientId clientId;

  /// The refresh token resulting from a OAuth2 consent flow.
  final String refreshToken;

  /// Creates a new [UserCredentials] from JSON.
  ///
  /// [json] can be either a [Map] or a JSON map encoded as a [String].
  factory UserCredentials.fromJson(json) {
    if (json is String) {
      json = JSON.decode(json);
    }
    if (json is! Map) {
      throw new ArgumentError('json must be a Map or a String encoding a Map.');
    }
    var clientId = json['client_id'];
    var clientSecret = json['client_secret'];
    var refreshToken = json['refresh_token'];
    var type = json['type'];

    if (type != 'authorized_user') {
      throw new ArgumentError('The given credentials are not of type '
          'service_account (was: $type).');
    }

    if (clientId == null || clientSecret == null || refreshToken == null) {
      throw new ArgumentError('The given credentials do not contain all the '
          'fields: client_id, client_secret and refresh_token.');
    }

    return new UserCredentials(
        new ClientId(clientId, clientSecret), refreshToken);
  }

  /// Creates a new [UserCredentials].
  UserCredentials(this.clientId, this.refreshToken);
}

/// Obtain oauth2 [AccessCredentials] using service account credentials.
///
/// In case the service account has no access to the requested scopes or another
/// error occurs the returned future will complete with an `Exception`.
///
/// [client] will be used for obtaining `AccessCredentials`.
///
/// The [ServiceAccountCredentials] can be obtained in the Google Cloud Console.
Future<AccessCredentials> obtainAccessCredentialsViaUserAccount(
    UserCredentials clientCredentials,
    List<String> scopes,
    http.Client baseClient) {
  return new _Flow(clientCredentials.clientId, clientCredentials.refreshToken,
          scopes, baseClient)
      .run();
}

class _Flow {
  static const _grantType = 'refresh_token';
  static const _googleOAuth2TokenUrl =
      'https://accounts.google.com/o/oauth2/token';

  final ClientId _clientId;
  final String _refreshToken;
  final List<String> _scopes;
  final http.Client _client;

  _Flow(this._clientId, this._refreshToken, this._scopes, this._client);

  Future<AccessCredentials> run() async {
    var requestParameters =
        'client_id=${Uri.encodeComponent(_clientId.identifier)}&'
        'client_secret=${Uri.encodeComponent(_clientId.secret)}&'
        'refresh_token=${Uri.encodeComponent(_refreshToken)}&'
        'grant_type=${Uri.encodeComponent(_grantType)}';

    var body = new Stream<List<int>>.fromIterable(
        <List<int>>[UTF8.encode(requestParameters)]);
    var request =
        new _RequestImpl('POST', Uri.parse(_googleOAuth2TokenUrl), body);
    request.headers['content-type'] = contentTypeUrlEncoded;

    var httpResponse = await _client.send(request);
    var object = await httpResponse.stream
        .transform(UTF8.decoder)
        .transform(JSON.decoder)
        .first;
    Map response = object as Map;
    var tokenType = response['token_type'];
    var token = response['access_token'];
    var expiresIn = response['expires_in'];
    var error = response['error'];

    if (httpResponse.statusCode != 200 && error != null) {
      throw new Exception('Unable to obtain credentials. Error: $error.');
    }

    if (tokenType != 'Bearer' || token == null || expiresIn is! int) {
      throw new Exception(
          'Unable to obtain credentials. Invalid response from server.');
    }
    var accessToken = new AccessToken(tokenType, token, expiryDate(expiresIn));
    return new AccessCredentials(accessToken, null, _scopes);
  }
}

class _RequestImpl extends http.BaseRequest {
  final Stream<List<int>> _stream;

  _RequestImpl(String method, Uri url, [Stream<List<int>> stream])
      : _stream = stream == null ? new Stream.fromIterable([]) : stream,
        super(method, url);

  http.ByteStream finalize() {
    super.finalize();
    if (_stream == null) {
      return null;
    }
    return new http.ByteStream(_stream);
  }
}

