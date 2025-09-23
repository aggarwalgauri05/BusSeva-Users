// lib/screens/recommendations_screen.dart (patched)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/recommendation_service.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});
  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _recService = RecommendationService();
  Future<List<BusRec>>? _future;
  String? _indexUrlHint; // optional: link from error message if present

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = _uid ?? 'guest';
    _indexUrlHint = null;
    _future = _wrapped(uid);
    setState(() {});
  }

  Future<List<BusRec>> _wrapped(String uid) async {
    try {
      return await _recService.getUserRecommendations(uid, topK: 10);
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Extract console link if present (don’t hardcode; Firestore sends it)
        final msg = e.message ?? '';
        final match = RegExp(r'https://console\.firebase\.google\.com[^\s]+')
            .firstMatch(msg);
        _indexUrlHint = match?.group(0);
      }
      rethrow;
    }
  }

  Future<void> _refresh() async {
    _load();
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f1280),
      appBar: AppBar(
        title: const Text('Recommended for You'),
        backgroundColor: const Color(0xff0f1280),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BusRec>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final err = snap.error;
              final isIndex = err is FirebaseException && err.code == 'failed-precondition';
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    isIndex
                        ? 'Index required for this query.\nApprove it in Firebase Console, then pull to refresh.'
                        : 'Error: $err',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (_indexUrlHint != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tip: Open the console link shown in the error toast to auto-create the index.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            final recs = snap.data ?? const <BusRec>[];
            if (recs.isEmpty) {
              return const Center(
                child: Text('No recommendations yet', style: TextStyle(color: Colors.white70)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: recs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = recs[i];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3437C7), Color(0xFF5A5DDC)],
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      r.name ?? 'Bus ${r.busId}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if (r.route != null) r.route!,
                        'Score: ${r.score.toStringAsFixed(2)}',
                        'Content: ${r.contentScore.toStringAsFixed(2)}',
                        'CF: ${r.cfScore.toStringAsFixed(2)}',
                      ].join('  •  '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () {},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
