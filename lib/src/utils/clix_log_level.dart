enum ClixLogLevel {
  verbose(0),
  debug(1),
  info(2),
  warning(3),
  error(4),
  none(5);

  const ClixLogLevel(this.level);

  final int level;

  bool operator >=(ClixLogLevel other) => level >= other.level;
  bool operator <=(ClixLogLevel other) => level <= other.level;
  bool operator >(ClixLogLevel other) => level > other.level;
  bool operator <(ClixLogLevel other) => level < other.level;

  bool shouldLog(ClixLogLevel messageLevel) => this <= messageLevel;
}
