import 'dart:math' as math;

/// Versioned deterministic streams; no dependence on Dart Random implementation.
const stochasticVersion = 'xorshift32-beta-binomial-ptrs-1';

class SeededRandom {
  int state;
  SeededRandom(int seed)
    : state = (seed & 0xffffffff) == 0 ? 0x6d2b79f5 : seed & 0xffffffff;
  double uniform() {
    var x = state;
    x ^= (x << 13) & 0xffffffff;
    x ^= x >> 17;
    x ^= (x << 5) & 0xffffffff;
    state = x & 0xffffffff;
    return (state + .5) / 4294967296;
  }

  double normal() =>
      math.sqrt(-2 * math.log(uniform())) * math.cos(2 * math.pi * uniform());
  double gamma(double shape) {
    if (!shape.isFinite || shape <= 0) {
      throw ArgumentError('Positive gamma shape');
    }
    if (shape < 1) return gamma(shape + 1) * math.pow(uniform(), 1 / shape);
    final d = shape - 1 / 3, c = 1 / math.sqrt(9 * d);
    for (int attempts = 0; attempts < 10000; attempts++) {
      final x = normal(), base = 1 + c * x;
      if (base <= 0) continue;
      final v = base * base * base, u = uniform();
      if (u < 1 - .0331 * x * x * x * x ||
          math.log(u) < .5 * x * x + d * (1 - v + math.log(v))) {
        return d * v;
      }
    }
    throw StateError('Gamma sampler failed; no observation assigned');
  }

  /// Exact beta-order-statistic decomposition. O(log n), never n Bernoulli
  /// trials for a macroscopic source. Only terminal blocks <=32 are individual.
  int binomial(int n, double p) {
    if (n < 0 || n > 1000000000 || !p.isFinite || p < 0 || p > 1) {
      throw ArgumentError('Binomial n≤1e9 and probability0…1');
    }
    if (p == 0 || n == 0) return 0;
    if (p == 1) return n;
    int offset = 0;
    while (n > 32) {
      final a = 1 + n ~/ 2,
          b = n - a + 1,
          x = gamma(a.toDouble()),
          y = gamma(b.toDouble()),
          u = x / (x + y);
      if (u >= p) {
        n = a - 1;
        p = (p / u).clamp(0, 1);
      } else {
        offset += a;
        n = b - 1;
        p = ((p - u) / (1 - u)).clamp(0, 1);
      }
    }
    for (int i = 0; i < n; i++) {
      if (uniform() < p) offset++;
    }
    return offset;
  }

  int poisson(double mean) {
    if (!mean.isFinite || mean < 0 || mean > 1e9) {
      throw ArgumentError('Poisson mean0…1e9');
    }
    if (mean == 0) return 0;
    if (mean < 30) {
      final limit = math.exp(-mean);
      double product = 1;
      int k = 0;
      do {
        k++;
        product *= uniform();
      } while (product > limit);
      return k - 1;
    }
    // Hörmann transformed rejection (PTRS), exact Poisson acceptance test.
    final b = .931 + 2.53 * math.sqrt(mean),
        a = -.059 + .02483 * b,
        invAlpha = 1.1239 + 1.1328 / (b - 3.4),
        vr = .9277 - 3.6224 / (b - 2);
    for (int tries = 0; tries < 10000; tries++) {
      final u = uniform() - .5,
          v = uniform(),
          us = .5 - u.abs(),
          k = ((2 * a / us + b) * u + mean + .43).floor();
      if (k < 0) continue;
      if (us >= .07 && v <= vr) return k;
      if (us < .013 && v > us) continue;
      if (math.log(v * invAlpha / (a / (us * us) + b)) <=
          -mean + k * math.log(mean) - logGamma(k + 1.0)) {
        return k;
      }
    }
    throw StateError('Poisson sampler failed; no observation assigned');
  }
}

double logGamma(double z) {
  const coefficients = [
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  if (z < .5) {
    return math.log(math.pi) -
        math.log(math.sin(math.pi * z)) -
        logGamma(1 - z);
  }
  z -= 1;
  double x = .99999999999980993;
  for (int i = 0; i < coefficients.length; i++) {
    x += coefficients[i] / (z + i + 1);
  }
  final t = z + 7.5;
  return .5 * math.log(2 * math.pi) + (z + .5) * math.log(t) - t + math.log(x);
}

/// Normalized trapezoid CDF of a nonnegative continuous density on a uniform
/// grid. Reused for every detection; interpolation makes the grid approximation
/// explicit, rather than substituting an unrelated random visual pattern.
class ProbabilityGrid {
  final double min, max;
  final List<double> density, cdf;
  final double rawIntegral;
  ProbabilityGrid._(
    this.min,
    this.max,
    this.density,
    this.cdf,
    this.rawIntegral,
  );
  factory ProbabilityGrid(
    double min,
    double max,
    double Function(double) pdf, {
    int intervals = 4096,
  }) {
    if (!min.isFinite ||
        !max.isFinite ||
        max <= min ||
        intervals < 16 ||
        intervals > 32768) {
      throw ArgumentError('Finite distribution domain/grid');
    }
    final dx = (max - min) / intervals,
        ys = [for (int i = 0; i <= intervals; i++) pdf(min + dx * i)],
        cdf = List<double>.filled(intervals + 1, 0);
    if (ys.any((v) => !v.isFinite || v < 0)) {
      throw ArgumentError('Finite nonnegative probability density');
    }
    for (int i = 1; i <= intervals; i++) {
      cdf[i] = cdf[i - 1] + dx * (ys[i - 1] + ys[i]) / 2;
    }
    final integral = cdf.last;
    if (integral <= 0 || !integral.isFinite) {
      throw ArgumentError('Nonzero probability integral');
    }
    return ProbabilityGrid._(
      min,
      max,
      ys.map((y) => y / integral).toList(),
      cdf.map((p) => p / integral).toList(),
      integral,
    );
  }
  double get dx => (max - min) / (density.length - 1);
  double cumulative(double x) {
    if (x <= min) return 0;
    if (x >= max) return 1;
    final index = (x - min) / dx, i = index.floor();
    return cdf[i] + (cdf[i + 1] - cdf[i]) * (index - i);
  }

  double probabilityDensity(double x) {
    if (x < min || x > max) return 0;
    final index = ((x - min) / dx).clamp(0, density.length - 1),
        i = index.floor();
    if (i == density.length - 1) return density.last;
    return density[i] + (density[i + 1] - density[i]) * (index - i);
  }

  double sample(SeededRandom rng) {
    final p = rng.uniform();
    int lo = 0, hi = cdf.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (cdf[mid] < p) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final frac = (p - cdf[lo]) / (cdf[hi] - cdf[lo]);
    return min + dx * (lo + frac);
  }
}
