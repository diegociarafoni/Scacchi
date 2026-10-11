import 'dart:math' as math;

/// Esito di una partita (o di un puzzle) contro un avversario.
class GameResult {
  const GameResult({
    required this.opponent,
    required this.opponentDeviation,
    required this.score,
  });

  final double opponent;
  final double opponentDeviation;

  /// 1 vittoria, 0.5 patta, 0 sconfitta.
  final double score;
}

/// Punteggio Glicko-2 (Glickman, 2012).
class Glicko2Rating {
  const Glicko2Rating({
    this.rating = 1500,
    this.deviation = 350,
    this.volatility = 0.06,
  });

  factory Glicko2Rating.fromJson(Map<String, dynamic> json) => Glicko2Rating(
    rating: (json['r'] as num).toDouble(),
    deviation: (json['d'] as num).toDouble(),
    volatility: (json['v'] as num).toDouble(),
  );

  static const minDeviation = 45.0;
  static const maxDeviation = 350.0;
  static const _scale = 173.7178;

  final double rating;
  final double deviation;
  final double volatility;

  Map<String, dynamic> toJson() => {
    'r': rating,
    'd': deviation,
    'v': volatility,
  };

  Glicko2Rating update(List<GameResult> games, {double tau = 0.75}) {
    final mu = (rating - 1500) / _scale;
    final phi = deviation / _scale;
    if (games.isEmpty) {
      final p = math.sqrt(phi * phi + volatility * volatility) * _scale;
      return _copy(rating, p, volatility);
    }
    var vInv = 0.0;
    var deltaSum = 0.0;
    for (final g in games) {
      final muJ = (g.opponent - 1500) / _scale;
      final gPhi = _g(g.opponentDeviation / _scale);
      final e = 1 / (1 + math.exp(-gPhi * (mu - muJ)));
      vInv += gPhi * gPhi * e * (1 - e);
      deltaSum += gPhi * (g.score - e);
    }
    final v = 1 / vInv;
    final delta = v * deltaSum;
    final sigma = _newVolatility(phi, v, delta, tau);
    final phiStar = math.sqrt(phi * phi + sigma * sigma);
    final newPhi = 1 / math.sqrt(1 / (phiStar * phiStar) + 1 / v);
    final newMu = mu + newPhi * newPhi * deltaSum;
    return _copy(newMu * _scale + 1500, newPhi * _scale, sigma);
  }

  Glicko2Rating _copy(double r, double d, double v) => Glicko2Rating(
    rating: r,
    deviation: d.clamp(minDeviation, maxDeviation),
    volatility: v,
  );

  static double _g(double phi) =>
      1 / math.sqrt(1 + 3 * phi * phi / (math.pi * math.pi));

  double _newVolatility(double phi, double v, double delta, double tau) {
    final a = math.log(volatility * volatility);
    double f(double x) {
      final ex = math.exp(x);
      final d = phi * phi + v + ex;
      return ex * (delta * delta - d) / (2 * d * d) - (x - a) / (tau * tau);
    }

    var lo = a;
    double hi;
    if (delta * delta > phi * phi + v) {
      hi = math.log(delta * delta - phi * phi - v);
    } else {
      var k = 1;
      while (f(a - k * tau) < 0) {
        k++;
      }
      hi = a - k * tau;
    }
    var fLo = f(lo);
    var fHi = f(hi);
    while ((hi - lo).abs() > 1e-6) {
      final c = lo + (lo - hi) * fLo / (fHi - fLo);
      final fC = f(c);
      if (fC * fHi <= 0) {
        lo = hi;
        fLo = fHi;
      } else {
        fLo /= 2;
      }
      hi = c;
      fHi = fC;
    }
    return math.exp(lo / 2);
  }

  @override
  bool operator ==(Object other) =>
      other is Glicko2Rating &&
      other.rating == rating &&
      other.deviation == deviation &&
      other.volatility == volatility;

  @override
  int get hashCode => Object.hash(rating, deviation, volatility);
}
