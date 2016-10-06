// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart';
import 'package:googleapis_auth_default_credentials/googleapis_auth_default_credentials.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart';

const _SCOPES = const [StorageApi.DevstorageReadOnlyScope];

main() async {
  Client client = new Client();
  AccessCredentials credentials = await obtainDefaultAccessCredentials(_SCOPES, client);
  AuthClient authClient = authenticatedClient(client, credentials);
  final storage = new StorageApi(authClient);
  final buckets = await storage.buckets.list('test');
  print(buckets.toJson());
  client.close();
}

