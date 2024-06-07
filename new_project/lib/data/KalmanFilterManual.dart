class Kalman {
  double Q_angle = 0.001;
  double Q_bias = 0.003;
  double R_measure = 0.03;

  double angle = 0; // Reset angle
  double bias = 0; // Reset bias
  double rate = 0;

  List<List<double>> P = [
    [0.0, 0.0],
    [0.0, 0.0]
  ];

  double y = 0; // Angle difference
  double S = 0; // Estimate error
  List<double> K = [0.0, 0.0]; // Kalman gain

  Kalman();

  // The angle should be in degrees and the rate should be in degrees per second and the delta time in seconds
  double getAngle(double newAngle, double newRate, double dt) {
    // Discrete Kalman filter time update equations - Time Update ("Predict")
    // Update xhat - Project the state ahead
    /* Step 1 */
    rate = newRate - bias;
    angle += dt * rate;

    // Update estimation error covariance - Project the error covariance ahead
    /* Step 2 */
    P[0][0] += dt * (dt * P[1][1] - P[0][1] - P[1][0] + Q_angle);
    P[0][1] -= dt * P[1][1];
    P[1][0] -= dt * P[1][1];
    P[1][1] += Q_bias * dt;

    // Discrete Kalman filter measurement update equations - Measurement Update ("Correct")
    // Calculate Kalman gain - Compute the Kalman gain
    /* Step 4 */
    S = P[0][0] + R_measure;
    /* Step 5 */
    K[0] = P[0][0] / S;
    K[1] = P[1][0] / S;

    // Calculate angle and bias - Update estimate with measurement zk (newAngle)
    /* Step 3 */
    y = newAngle - angle;
    /* Step 6 */
    angle += K[0] * y;
    bias += K[1] * y;

    // Calculate estimation error covariance - Update the error covariance
    /* Step 7 */
    P[0][0] -= K[0] * P[0][0];
    P[0][1] -= K[0] * P[0][1];
    P[1][0] -= K[1] * P[0][0];
    P[1][1] -= K[1] * P[0][1];

    return angle;
  }
}
