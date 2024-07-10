class MovingAverage {
  final int windowSize;
  List<double> values;
  double _sum;

  MovingAverage(this.windowSize)
      : values = [],
        _sum = 0;

  void addValue(double value) {
    // If the window is full, remove the oldest value from the sum and list
    if (values.length == windowSize) {
      _sum -= values.removeAt(0);
    }

    // Add the new value to the sum and the list
    values.add(value);
    _sum += value;
  }

  double getAverage() {
    // Return the average if there are any values, otherwise return 0
    if (values.isEmpty) return 0;
    return _sum / values.length;
  }
}

void main() {
  // Create a moving average filter with a window size of 3
  var ma = MovingAverage(3);

  // Add values and print the moving average
  ma.addValue(10);
  print(ma.getAverage()); // Output: 10.0

  ma.addValue(20);
  print(ma.getAverage()); // Output: 15.0

  ma.addValue(30);
  print(ma.getAverage()); // Output: 20.0

  ma.addValue(40);
  print(ma.getAverage()); // Output: 30.0

  ma.addValue(50);
  print(ma.getAverage()); // Output: 40.0
}

//https://pub.dev/packages/moving_average
//alternative implementation