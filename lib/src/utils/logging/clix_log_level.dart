enum ClixLogLevel {
  none(0),
  error(1),
  warn(2),
  info(3),
  debug(4);

  const ClixLogLevel(this.value);

  final int value;

  bool shouldLog(ClixLogLevel level) {
    return value >= level.value;
  }

  bool operator <(ClixLogLevel other) => value < other.value;
  bool operator <=(ClixLogLevel other) => value <= other.value;
  bool operator >(ClixLogLevel other) => value > other.value;
  bool operator >=(ClixLogLevel other) => value >= other.value;
}
