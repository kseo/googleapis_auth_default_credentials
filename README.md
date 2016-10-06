# googleapis_auth_default_credentials

This package provides an implementation of application default
credentials for Dart.

The Application Default Credentials provide a simple way to get
authorization credentials for use in calling Google APIs.

They are best suited for cases when the call needs to have the same
identity and authorization level for the application independent of
the user. This is the recommended approach to authorize calls to Cloud
APIs, particularly when you're building an application that uses
Google Compute Engine.

## Example

```dart
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
```

