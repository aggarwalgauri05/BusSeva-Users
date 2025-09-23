// lib/services/recommendation_service.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class BusRec {
  final String busId;
  final double score;
  final double contentScore;
  final double cfScore;
  final Map<String, double> weights;
  final Map<String, double> busRatings;
  final String? name;
  final String? route;
  BusRec({
    required this.busId,
    required this.score,
    required this.contentScore,
    required this.cfScore,
    required this.weights,
    required this.busRatings,
    this.name,
    this.route,
  });
}

class RecommendationService {
  final FirebaseFirestore _db;
  RecommendationService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<BusRec>> getUserRecommendations(
    String userId, {
    int topK = 10,
    int userHistoryLimit = 50,
    int candidateCap = 400,
    int minReviews = 3,
    int neighborLimitPerAnchor = 200,
    int maxAnchors = 5,
    bool onlyVerified = true,
  }) async {
    // 1) Fetch user history
    Query reviewsQ = _db
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('reviewDate', descending: true)
        .limit(userHistoryLimit);
    if (onlyVerified) {
      reviewsQ = _db.collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('isVerified', isEqualTo: true)
          .orderBy('reviewDate', descending: true)
          .limit(userHistoryLimit);
    }
    final userSnap = await reviewsQ.get();
    final userReviews = userSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

    final coldStart = userReviews.isEmpty;

    // 2) Derive user weights from multi-criteria
    final sums = {'overall': 0.0, 'cleanliness': 0.0, 'punctuality': 0.0, 'safety': 0.0, 'driver': 0.0};
    for (final r in userReviews) {
      sums['overall'] = sums['overall']! + (r['overallRating'] ?? 0).toDouble();
      sums['cleanliness'] = sums['cleanliness']! + (r['cleanlinessRating'] ?? 0).toDouble();
      sums['punctuality'] = sums['punctuality']! + (r['punctualityRating'] ?? 0).toDouble();
      sums['safety'] = sums['safety']! + (r['safetyRating'] ?? 0).toDouble();
      sums['driver'] = sums['driver']! + (r['driverRating'] ?? 0).toDouble();
    }
    Map<String, double> weights = coldStart
        ? {'overall': 0.4, 'cleanliness': 0.15, 'punctuality': 0.2, 'safety': 0.15, 'driver': 0.1}
        : {
            'overall': sums['overall']! / userReviews.length,
            'cleanliness': sums['cleanliness']! / userReviews.length,
            'punctuality': sums['punctuality']! / userReviews.length,
            'safety': sums['safety']! / userReviews.length,
            'driver': sums['driver']! / userReviews.length,
          };
    final wsum = weights.values.fold<double>(0, (a, b) => a + b);
    weights = weights.map((k, v) => MapEntry(k, wsum == 0 ? 0 : v / wsum));

    // 3) Candidate buses
    final candidateSnap = await _db
        .collection('buses')
        .where('ratings.totalReviews', isGreaterThan: minReviews)
        .limit(candidateCap)
        .get();
    final busDocs = candidateSnap.docs.map((d) => {'id': d.id, ...((d.data() as Map<String, dynamic>))}).toList();

    // 4) Content score function
    double contentScore(Map<String, dynamic> b) {
      final r = (b['ratings'] as Map<String, dynamic>?) ?? {};
      final o = (r['overall'] ?? 0).toDouble();
      final c = (r['cleanliness'] ?? 0).toDouble();
      final p = (r['punctuality'] ?? 0).toDouble();
      final s = (r['safety'] ?? 0).toDouble();
      final dr = (r['driver'] ?? 0).toDouble();
      return weights['overall']! * o +
          weights['cleanliness']! * c +
          weights['punctuality']! * p +
          weights['safety']! * s +
          weights['driver']! * dr;
    }

    // 5) Build neighborhood from anchor buses
    final userByBus = <String, double>{};
    for (final r in userReviews) {
      userByBus[r['busId']] = (r['overallRating'] ?? 0).toDouble();
    }
    final ratedSet = userByBus.keys.toSet();
    final anchors = userReviews.take(maxAnchors).map((r) => r['busId'] as String).toList();

    // neighborRatingsByUser: uid -> {common: List<[me, other]>, ratings: busId->rating}
    final neighborRatingsByUser = <String, Map<String, dynamic>>{};
    for (final busId in anchors) {
      Query q = _db
          .collection('reviews')
          .where('busId', isEqualTo: busId)
          .orderBy('reviewDate', descending: true)
          .limit(neighborLimitPerAnchor);
      if (onlyVerified) {
        q = _db
            .collection('reviews')
            .where('busId', isEqualTo: busId)
            .where('isVerified', isEqualTo: true)
            .orderBy('reviewDate', descending: true)
            .limit(neighborLimitPerAnchor);
      }
      final others = await q.get();
      for (final d in others.docs) {
        final rv = d.data() as Map<String, dynamic>;
        final otherUid = rv['userId'] as String?;
        if (otherUid == null || otherUid == userId) continue;
        final me = userByBus[busId];
        if (me == null) continue;
        final entry = neighborRatingsByUser[otherUid] ??
            {
              'common': <List<double>>[],
              'ratings': <String, double>{},
            };
        (entry['common'] as List<List<double>>).add([me, (rv['overallRating'] ?? 0).toDouble()]);
        (entry['ratings'] as Map<String, double>)[rv['busId']] = (rv['overallRating'] ?? 0).toDouble();
        neighborRatingsByUser[otherUid] = entry;
      }
    }

    double cosine(List<List<double>> common) {
      double dot = 0, nx = 0, ny = 0;
      for (final pair in common) {
        final a = pair[0], b = pair[1];
        dot += a * b;
        nx += a * a;
        ny += b * b;
      }
      if (nx == 0 || ny == 0) return 0;
      return dot / (math.sqrt(nx) * math.sqrt(ny));
    }

    final neighbors = <Map<String, dynamic>>[];
    neighborRatingsByUser.forEach((uid, bundle) {
      final sim = cosine(bundle['common'] as List<List<double>>);
      if (sim > 0) {
        neighbors.add({'uid': uid, 'sim': sim, 'ratings': bundle['ratings'] as Map<String, double>});
      }
    });
    neighbors.sort((a, b) => (b['sim'] as double).compareTo(a['sim'] as double));
    final topNeighbors = neighbors.take(20).toList();

    // 6) Score candidates and rank
    final alpha = coldStart ? 0.8 : 0.55; // blend more content in cold-start
    final results = <BusRec>[];

    for (final b in busDocs) {
      final busId = b['id'] as String;
      if (ratedSet.contains(busId)) continue;

      final cScore = contentScore(b);

      // CF prediction: weighted average of neighbor ratings
      double num = 0, den = 0;
      for (final nbh in topNeighbors) {
        final rmap = nbh['ratings'] as Map<String, double>;
        final r = rmap[busId];
        if (r == null) continue;
        final sim = nbh['sim'] as double;
        num += sim * r;
        den += sim;
      }
      final cfScore = den > 0 ? num / den : 0.0;

      final finalScore = alpha * cScore + (1 - alpha) * cfScore;

      final ratings = (b['ratings'] as Map<String, dynamic>?) ?? {};
      results.add(BusRec(
        busId: busId,
        score: finalScore,
        contentScore: cScore,
        cfScore: cfScore,
        weights: Map<String, double>.from(weights),
        busRatings: {
          'overall': (ratings['overall'] ?? 0).toDouble(),
          'cleanliness': (ratings['cleanliness'] ?? 0).toDouble(),
          'punctuality': (ratings['punctuality'] ?? 0).toDouble(),
          'safety': (ratings['safety'] ?? 0).toDouble(),
          'driver': (ratings['driver'] ?? 0).toDouble(),
        },
        name: (b['name'] as String?),
        route: (b['route'] as String?),
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topK).toList();
  }
}
