import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GymDetailScreen extends StatefulWidget {
  final Map<String, dynamic> gym;

  const GymDetailScreen({super.key, required this.gym});

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {

  late int _currentOccupancy;
  late int _maxCapacity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentOccupancy = widget.gym['current_occupancy'] as int? ?? 0;
    _maxCapacity = widget.gym['max_capacity'] as int? ?? 50;
  }

  // ─── DIALOG ───────────────────────────────────────────────────────────────

  void _showEnterGymDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Enter Gym?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You are about to enter ${widget.gym['name']}. Please have your NFC ready.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNfcScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8FF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Yes, Enter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── NFC SCREEN ───────────────────────────────────────────────────────────

  void _showNfcScreen() async {
    bool nfcAvailable = false;

    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      nfcAvailable = availability == NFCAvailability.available;
      print('NFC Status: $availability');
    } catch (e) {
      nfcAvailable = false;
      print('NFC Error: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // nfc icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                shape: BoxShape.circle,
                border: Border.all(
                  color: nfcAvailable
                      ? const Color(0xFFE8FF00)
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.nfc,
                color: nfcAvailable
                    ? const Color(0xFFE8FF00)
                    : Colors.grey,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // title
            Text(
              nfcAvailable ? 'Tap Your NFC' : 'NFC Not Available',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // subtitle
            Text(
              nfcAvailable
                  ? 'NFC is active. Hold your phone near\nthe reader at the gym entrance.'
                  : 'Your device does not support NFC\nor it is turned off.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // debug button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                children: [
                  const Text(
                    '🛠 Debug Mode - No NFC Reader Yet',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await FlutterNfcKit.finish();
                      } catch (_) {}
                      if (context.mounted) Navigator.pop(context);
                      _handleNfcSuccess();
                    },
                    icon: const Icon(Icons.touch_app, size: 18),
                    label: const Text('Simulate NFC Tap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async{
                  try{
                    await FlutterNfcKit.finish();
                  }catch(_){}
                  if(context.mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );

    // real nfc polling — waits for actual tag if nfc is available
    if (nfcAvailable) {
      try {
        await FlutterNfcKit.poll(timeout: const Duration(seconds: 30));
        await FlutterNfcKit.finish();
        if (mounted) {
          Navigator.pop(context);
          _handleNfcSuccess();
        }
      } catch (e) {
        try {
          await FlutterNfcKit.finish();
        } catch (_) {}
      }
    }
  }

  // ─── HANDLE SUCCESS ───────────────────────────────────────────────────────

  Future<void> _handleNfcSuccess() async {
    setState(() => _isLoading = true);

    try {
      final newOccupancy = _currentOccupancy + 1;

      await Supabase.instance.client
          .from('gyms')
          .update({'current_occupancy': newOccupancy})
          .eq('id', widget.gym['id']);

      setState(() {
        _currentOccupancy = newOccupancy;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entry recorded! Enjoy your workout!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record entry: $e')),
        );
      }
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final percentage = _currentOccupancy / _maxCapacity;

    Color occupancyColor;
    if (percentage < 0.5) {
      occupancyColor = Colors.green;
    } else if (percentage < 0.8) {
      occupancyColor = Colors.orange;
    } else {
      occupancyColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [

          // top image with back button
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.gym['image_url'] != null
                  ? Image.network(
                      widget.gym['image_url'],
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.grey,
                        size: 64,
                      ),
                    ),
            ),
          ),

          // gym info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // gym name
                  Text(
                    widget.gym['name'] ?? 'Unknown Gym',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                        widget.gym['location'] ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        softWrap: true,
                      ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // occupancy title
                  const Text(
                    'Current Occupancy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // occupancy count
                  Row(
                    children: [
                      Icon(Icons.people, color: occupancyColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$_currentOccupancy / $_maxCapacity people',
                        style: TextStyle(
                          color: occupancyColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // progress bar
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: occupancyColor,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),

                  // percentage text
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}% full',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 48),

                  // enter gym button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _showEnterGymDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8FF00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Enter Gym',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}