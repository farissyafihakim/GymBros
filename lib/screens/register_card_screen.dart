import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterCardScreen extends StatefulWidget {
  const RegisterCardScreen({super.key});

  @override
  State<RegisterCardScreen> createState() => _RegisterCardScreenState();
}

class _RegisterCardScreenState extends State<RegisterCardScreen> {
  bool _isScanning = false;
  String? _scannedCardId;

  // listens for a card tap and reads its unique id
  Future<void> _scanCard() async {
    setState(() => _isScanning = true);

    try {
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 30),
      );
      await FlutterNfcKit.finish();

      setState(() {
        _scannedCardId = tag.id;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }

  // saves the scanned card id to this user's profile
  Future<void> _saveCard() async {
    if (_scannedCardId == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'nfc_card_id': _scannedCardId})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Card registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save card: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Register Your Card',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc,
              size: 80,
              color: _scannedCardId != null
                  ? Colors.green
                  : const Color(0xFFE8FF00),
            ),
            const SizedBox(height: 24),
            Text(
              _scannedCardId != null
                  ? 'Card detected!'
                  : 'Tap your card to register it',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_scannedCardId != null) ...[
              const SizedBox(height: 12),
              Text(
                'ID: $_scannedCardId',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _scanCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isScanning
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_scannedCardId != null
                        ? 'Scan Again'
                        : 'Start Scanning'),
              ),
            ),
            if (_scannedCardId != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save This Card'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}