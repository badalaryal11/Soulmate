/// A utility class for rate limiting function calls based on a specific key.
/// Useful for throttling API calls, UI interactions, etc.
class RateLimiter {
  static final Map<String, _RateLimitData> _limits = {};

  /// Checks if a request for the given [key] is allowed based on the [cooldown].
  ///
  /// Returns `true` if allowed (and updates the last request time), `false` if throttled.
  ///
  /// Optionally supports bursts: [maxBurst] defines how many rapid requests are
  /// allowed before the strict [cooldown] is enforced.
  static bool check(String key, Duration cooldown, {int maxBurst = 1}) {
    final now = DateTime.now();

    // If this is the very first time we've seen this key, allow it immediately
    if (!_limits.containsKey(key)) {
      _limits[key] = _RateLimitData(now);
      return true;
    }

    final data = _limits[key]!;

    // If enough time has passed since the last request, reset burst counter
    if (now.difference(data.lastRequestTime) > cooldown * maxBurst) {
      data.burstCount = 0;
    }

    if (now.difference(data.lastRequestTime) < cooldown) {
      if (data.burstCount < maxBurst - 1) {
        // Allowed due to burst capacity
        data.burstCount++;
        data.lastRequestTime = now;
        return true;
      }
      // Throttled
      return false;
    }

    // Allowed
    data.burstCount = 0;
    data.lastRequestTime = now;
    return true;
  }
}

class _RateLimitData {
  DateTime lastRequestTime;
  int burstCount = 0;

  _RateLimitData(this.lastRequestTime);
}
