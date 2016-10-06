// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as path;

import './user_credentials.dart';

const _credentialEnvVar = 'GOOGLE_APPLICATION_CREDENTIALS';

AccessCredentials _cachedCredentials;
bool _isGCE;

/// Obtains the default service-level credentials for the application.
Future<AccessCredentials> obtainDefaultAccessCredentials(
    List<String> scopes, Client baseClient) async {
  if (_cachedCredentials != null) {
    return _cachedCredentials;
  }

  var credentials;
  try {
    credentials = await _obtainCredentialsFromEnvVar(scopes, baseClient);
  } catch (_) {
    // Try next option.
  }
  try {
    if (credentials == null) {
      credentials =
          await _obtainCredentialsFromWellKnownFile(scopes, baseClient);
    }
  } catch (_) {
    // Try next option.
  }
  try {
    if (credentials == null && await _runningOnComputeEngine()) {
      credentials = await obtainAccessCredentialsViaMetadataServer(baseClient);
    }
  } catch (_) {
    // Try next option.
  }

  if (credentials == null) {
    throw new Exception('Unable to obtain credentials');
  }
  _cachedCredentials = credentials;
  return credentials;
}

Future<bool> _runningOnComputeEngine() async {
  if (_isGCE != null) {
    return _isGCE;
  }

  Response response;
  try {
    response = await get('http://metadata.google.internal');
    _isGCE = response.headers['metadata-flavor'] == 'Google';
  } catch (e) {
    _isGCE = false;
  }
  return _isGCE;
}

Future<AccessCredentials> _getCredentialsFromFilePath(
    List<String> scopes, String credentialsPath, Client baseClient) async {
  final file = new File(credentialsPath);
  if (!await file.exists()) {
    throw new Exception(
        'The file at $credentialsPath does not exist, or it is not a file.');
  }
  final json = JSON.decode(await file.readAsString());
  if (json['type'] == 'authorized_user') {
    return obtainAccessCredentialsViaUserAccount(
        new UserCredentials.fromJson(json), scopes, baseClient);
  } else {
    return obtainAccessCredentialsViaServiceAccount(
        new ServiceAccountCredentials.fromJson(json), scopes, baseClient);
  }
}

Future<AccessCredentials> _obtainCredentialsFromEnvVar(
    List<String> scopes, Client baseClient) async {
  final credentialsPath = Platform.environment[_credentialEnvVar];
  if (credentialsPath == null || credentialsPath.length == 0) {
    return null;
  }
  return _getCredentialsFromFilePath(scopes, credentialsPath, baseClient);
}

Future<AccessCredentials> _obtainCredentialsFromWellKnownFile(
    List<String> scopes, Client baseClient) async {
  String location;
  if (Platform.isWindows) {
    location = Platform.environment['APPDATA'];
  } else {
    // Linux or Mac
    final home = Platform.environment['HOME'];
    location = path.join(home, '.config');
  }
  location =
      path.join(location, 'gcloud', 'application_default_credentials.json');
  return _getCredentialsFromFilePath(scopes, location, baseClient);
}
