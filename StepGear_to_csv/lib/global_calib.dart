// globals.dart
library my_app.globals;

double currentKneeValue = 0.0;
double currentFootValue = 0.0;
double currentHipsValue = 0.0;

void incrementKneeValue() {
  currentKneeValue += 1.0;
}

void decrementKneeValue() {
  currentKneeValue -= 1.0;
}

void incrementFootValue() {
  currentFootValue += 1.0;
}

void decrementFootValue() {
  currentFootValue -= 1.0;
}

void incrementHipsValue() {
  currentHipsValue += 1.0;
}

void decrementHipsValue() {
  currentHipsValue -= 1.0;
}

void resetAll() {
  currentKneeValue = 0.0;
  currentFootValue = 0.0;
  currentHipsValue = 0.0;
}
