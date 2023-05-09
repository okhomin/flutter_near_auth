<!-- USAGE EXAMPLES -->

## Usage

> You need to replace configuration constants in the Flutter client depending on your domain, path, and redirect urls in the [main.dart](./lib/main.dart#L112-L116) file.
```dart
static const String _backendHost = 'localhost:8080';
static const String _failureURL = 'client://failure';
static const String _successURL = 'client://success';
static const String _nearLoginPath = '/near/index.html';
static const String _backendAuthPath = '/auth';
```

### Running Flutter client
> Don't forget to generate platform related files and run the backend before running the Flutter client.
> `flutter create --platforms=ios,android .`

[`main.dart`](./lib/main.dart) contains the Flutter client logic that is responsible for the authentication process.
To run the client you must have a connected device or emulator. But you may have to replace `localhost` with your local IP address in the [`main.dart`](./lib/main.dart#L112) file if you want to run the client on a real device.

```sh
flutter run
```
