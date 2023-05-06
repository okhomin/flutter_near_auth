import 'dart:convert';
import 'dart:typed_data';

import 'package:bs58/bs58.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _isAuthenticated = false;
  bool _inProgress = false;
  String _accountID = '';
  String _publicKey = '';
  String _token = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_inProgress) const CircularProgressIndicator(),
              if (_isAuthenticated)
                AccountInformation(
                    publicKey: _publicKey,
                    accountID: _accountID,
                    token: _token),
              if (!_isAuthenticated)
                const Text(
                  'You are not authenticated',
                  style: TextStyle(fontSize: 20),
                ),
              if (_isAuthenticated)
                LogoutButton(onPressed: () {
                  setState(() {
                    _isAuthenticated = false;
                    _accountID = '';
                    _publicKey = '';
                  });
                }),
              if (!_isAuthenticated)
                LoginButton(
                  onPressed: () {
                    setState(() {
                      _inProgress = true;
                    });
                  },
                  onSuccess:
                      (String accountID, String publicKey, String token) {
                    setState(() {
                      _isAuthenticated = true;
                      _inProgress = false;
                      _accountID = accountID;
                      _publicKey = publicKey;
                      _token = token;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NEARData {
  final String accountID;
  final String publicKey;
  final String signature;

  NEARData(
      {required this.accountID,
      required this.publicKey,
      required this.signature});

  // convert to json
  Map<String, dynamic> toJson() => {
        'account_id': accountID,
        'public_key': publicKey,
        'signature': signature,
      };
}

class AuthResponse {
  final String token;

  AuthResponse({required this.token});

  // convert from json
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
    );
  }
}

class LoginButton extends StatelessWidget {
  static const String _backendHost = 'localhost:8080';
  static const String _failureURL = 'client://failure';
  static const String _successURL = 'client://success';
  static const String _nearLoginPath = '/near/index.html';
  static const String _backendAuthPath = '/auth';

  final void Function(String accountID, String publicKey, String token)
      onSuccess;
  final void Function() onPressed;

  const LoginButton(
      {Key? key, required this.onSuccess, required this.onPressed})
      : super(key: key);

  Future<NEARData> _nearLogin() async {
    // generate ed25519 key pair
    final keyPair = ed.generateKey();

    // generated public key in base58 format
    final generatedPublicKey =
        'ed25519:${base58.encode(keyPair.publicKey.bytes as Uint8List)}';

    // generate uri for authentication
    final uri = Uri.http(_backendHost, _nearLoginPath, {
      'public_key': generatedPublicKey,
      'success_url': _successURL,
      'failure_url': _failureURL,
    });

    final result = await FlutterWebAuth.authenticate(
        url: uri.toString(), callbackUrlScheme: 'client');

    // if result is not success url, throw error
    if (!result.toString().startsWith(_successURL)) {
      throw Exception('Authentication failed');
    }

    final queryParameters = Uri.parse(result).queryParameters;

    // get account id from the result query parameters
    final accountID = queryParameters['account_id'];

    // get public key from the result query parameters
    final publicKey = queryParameters['public_key'];

    // create a signature with the generated private key and the account id
    final signature = base64Encode(
        ed.sign(keyPair.privateKey, utf8.encode(accountID!) as Uint8List));

    return NEARData(
        accountID: accountID, publicKey: publicKey!, signature: signature);
  }

  Future<AuthResponse> _backendLogin(NEARData data) async {
    final result = await http.post(Uri.http(_backendHost, _backendAuthPath),
        body: jsonEncode(data.toJson()));
    return AuthResponse.fromJson(jsonDecode(result.body));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        onPressed();
        final data = await _nearLogin();
        final token = await _backendLogin(data);
        onSuccess(data.accountID, data.publicKey, token.token);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
      ),
      child: const Text('Login with NEAR'),
    );
  }
}

class LogoutButton extends StatelessWidget {
  final void Function()? onPressed;

  const LogoutButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.redAccent,
      ),
      child: const Text('Logout'),
    );
  }
}

class AccountInformation extends StatelessWidget {
  final String publicKey;
  final String accountID;
  final String token;

  const AccountInformation(
      {Key? key,
      required this.publicKey,
      required this.accountID,
      required this.token})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Text(
            'Public Key: $publicKey',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Account ID: $accountID',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Backend Token: $token',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
