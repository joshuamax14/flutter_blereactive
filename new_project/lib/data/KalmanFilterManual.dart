class KalmanFilter {
  double _q; // Process noise covariance
  double _r; // Measurement noise covariance
  double _x; // Value
  double _p; // Estimation error covariance
  late double _k; // Kalman gain

  KalmanFilter(
      {required double q,
      required double r,
      required double initialP,
      required double initialX})
      : _q = q,
        _r = r,
        _p = initialP,
        _x = initialX;

  double filter(double measurement) {
    // Prediction update
    _p = _p + _q;

    // Measurement update
    _k = _p / (_p + _r);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;

    return _x;
  }

  double get value => _x;
}
