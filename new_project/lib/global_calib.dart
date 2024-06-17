// globals.dart
library my_app.globals;

double currentKneeValue = 0.0;
double currentFootValue = 0.0;
double currentHipsValue = 0.0;

void incrementKneeValue() {
  currentKneeValue += 0.1;
}

void decrementKneeValue() {
  currentKneeValue -= 0.1;
}

void incrementFootValue() {
  currentFootValue += 0.1;
}

void decrementFootValue() {
  currentFootValue -= 0.1;
}

void incrementHipsValue() {
  currentHipsValue += 0.1;
}

void decrementHipsValue() {
  currentHipsValue -= 0.1;
}
