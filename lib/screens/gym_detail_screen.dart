import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GymDetailScreen extends StatefulWidget {
  final Map<String, dynamic> gym;
  final Function(bool) onGymStatusChanged;

  const GymDetailScreen({
    super.key,
    required this.gym,
    required this.onGymStatusChanged,
  });

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  late int _currentOccupancy;
  late int _maxCapacity;
  bool _isLoading = false;
  bool _isInsideGym = false;
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _currentOccupancy = widget.gym['current_occupancy'] as int? ?? 0;
    _maxCapacity = widget.gym['max_capacity'] as int? ?? 50;
    _checkActiveSession();
  }

  // ─── CHECK SESSION ────────────────────────────────────────────────────────

  Future<void> _checkActiveSession() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('gym_sessions')
          .select()
          .eq('user_id', userId)
          .eq('gym_id', widget.gym['id'])
          .isFilter('exited_at', null)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isInsideGym = true;
          _activeSessionId = response['id'];
        });
      } else {
        setState(() {
          _isInsideGym = false;
          _activeSessionId = null;
        });
      }
    } catch (e) {
      print('Session check error: $e');
    }
  }

  // ─── ENTER DIALOG ─────────────────────────────────────────────────────────

  void _showEnterGymDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Enter Gym?',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You are about to enter ${widget.gym['name']}. Please have your NFC ready.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNfcScreen(isEntering: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8FF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Enter',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── EXIT DIALOG ──────────────────────────────────────────────────────────

  void _showExitGymDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit Gym?',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to exit ${widget.gym['name']}?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNfcScreen(isEntering: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Exit',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── NFC SCREEN ───────────────────────────────────────────────────────────

  void _showNfcScreen({required bool isEntering}) async {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
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
            Text(
              nfcAvailable
                  ? isEntering
                      ? 'Tap to Enter'
                      : 'Tap to Exit'
                  : 'NFC Not Available',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nfcAvailable
                  ? 'Hold your phone near the NFC reader\nat the gym entrance.'
                  : 'Your device does not support NFC\nor it is turned off.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
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
                      if (isEntering) {
                        _handleNfcEntry();
                      } else {
                        _handleNfcExit();
                      }
                    },
                    icon: const Icon(Icons.touch_app, size: 18),
                    label: Text(isEntering
                        ? 'Simulate Entry Tap'
                        : 'Simulate Exit Tap'),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await FlutterNfcKit.finish();
                  } catch (_) {}
                  if (context.mounted) Navigator.pop(context);
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
                  'Cancel',
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

    if (nfcAvailable) {
      try {
        await FlutterNfcKit.poll(timeout: const Duration(seconds: 30));
        await FlutterNfcKit.finish();
        if (mounted) {
          Navigator.pop(context);
          if (isEntering) {
            _handleNfcEntry();
          } else {
            _handleNfcExit();
          }
        }
      } catch (e) {
        try {
          await FlutterNfcKit.finish();
        } catch (_) {}
      }
    }
  }

  // ─── HANDLE ENTRY ─────────────────────────────────────────────────────────

  Future<void> _handleNfcEntry() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // check if already inside to prevent double entry
      final existing = await Supabase.instance.client
          .from('gym_sessions')
          .select()
          .eq('user_id', userId)
          .eq('gym_id', widget.gym['id'])
          .isFilter('exited_at', null)
          .maybeSingle();

      if (existing != null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ You are already inside this gym!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // create new session
      final session = await Supabase.instance.client
          .from('gym_sessions')
          .insert({
            'user_id': userId,
            'gym_id': widget.gym['id'],
            'entered_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // increase occupancy
      final newOccupancy = _currentOccupancy + 1;
      await Supabase.instance.client
          .from('gyms')
          .update({'current_occupancy': newOccupancy})
          .eq('id', widget.gym['id']);

      setState(() {
        _currentOccupancy = newOccupancy;
        _isInsideGym = true;
        _activeSessionId = session['id'];
        _isLoading = false;
      });

      // tell MainScreen user is now inside
      widget.onGymStatusChanged(true);

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

  // ─── HANDLE EXIT ──────────────────────────────────────────────────────────

  Future<void> _handleNfcExit() async {
    setState(() => _isLoading = true);

    try {
      if (_activeSessionId == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No active session found!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // update session with exit time
      await Supabase.instance.client
          .from('gym_sessions')
          .update({'exited_at': DateTime.now().toIso8601String()})
          .eq('id', _activeSessionId!);

      // decrease occupancy
      final newOccupancy =
          _currentOccupancy > 0 ? _currentOccupancy - 1 : 0;
      await Supabase.instance.client
          .from('gyms')
          .update({'current_occupancy': newOccupancy})
          .eq('id', widget.gym['id']);

      setState(() {
        _currentOccupancy = newOccupancy;
        _isInsideGym = false;
        _activeSessionId = null;
        _isLoading = false;
      });

      // tell MainScreen user has exited
      widget.onGymStatusChanged(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👋 Goodbye! See you next time!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record exit: $e')),
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
                      child: const Icon(Icons.fitness_center,
                          color: Colors.grey, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.gym['name'] ?? 'Unknown Gym',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.gym['location'] ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // inside gym banner
                  if (_isInsideGym)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'You are currently inside this gym',
                            style: TextStyle(
                                color: Colors.green, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Current Occupancy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: occupancyColor,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}% full',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 48),

                  // enter or exit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _isInsideGym
                              ? _showExitGymDialog
                              : _showEnterGymDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isInsideGym
                            ? Colors.red
                            : const Color(0xFFE8FF00),
                        foregroundColor: _isInsideGym
                            ? Colors.white
                            : Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: _isInsideGym
                                  ? Colors.white
                                  : Colors.black,
                            )
                          : Text(
                              _isInsideGym ? 'Exit Gym' : 'Enter Gym',
                              style: const TextStyle(
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