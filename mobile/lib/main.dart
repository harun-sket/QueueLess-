import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://hqjgdobuufuugpfkkwqc.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_apXbTiCpn-BxhjkWG5sM_A_T8S4nAYa'),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override Widget build(BuildContext context) => MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String email = '';
  String name = '';
  String phone = '';
  String message = '';

  Future<void> sendMagicLink() async {
    final res = await supabase.auth.signInWithOtp(email: email);
    if (res.error != null) setState(() => message = 'Error: ${res.error!.message}');
    else setState(() => message = 'Magic link sent to $email');
  }

  Future<void> joinQueue({required int businessId}) async {
    final response = await supabase.from('Queue').insert({
      'Name': name,
      'Phone': phone,
      'Email': email,
      'Status': 'Waiting',
      'business_id': businessId
    }).execute();
    if (response.error != null) setState(() => message = 'Error: ${response.error!.message}');
    else setState(() => message = 'Joined queue');
  }

  void onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.first.rawValue ?? '';
    final businessId = int.tryParse(code);
    if (businessId != null) joinQueue(businessId: businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QueueLess')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(decoration: const InputDecoration(labelText: 'Name'), onChanged: (v) => name = v),
          TextField(decoration: const InputDecoration(labelText: 'Phone'), onChanged: (v) => phone = v),
          TextField(decoration: const InputDecoration(labelText: 'Email'), onChanged: (v) => email = v),
          ElevatedButton(onPressed: sendMagicLink, child: const Text('Send Magic Link')),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 20),
          const Text('Scan business QR to join queue'),
          Expanded(child: MobileScanner(allowDuplicates: false, onDetect: onDetect)),
        ]),
      ),
    );
  }
}
