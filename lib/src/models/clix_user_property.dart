enum PropertyType {
  string,
  number,
  boolean;

  static PropertyType fromValue(dynamic value) {
    if (value is String) return PropertyType.string;
    if (value is num) return PropertyType.number;
    if (value is bool) return PropertyType.boolean;
    return PropertyType.string;
  }
}

class ClixUserProperty {
  final String name;
  final dynamic valueString;
  final PropertyType type;

  ClixUserProperty({
    required this.name,
    required this.valueString,
    PropertyType? type,
  }) : type = type ?? PropertyType.fromValue(valueString);

  Map<String, dynamic> toJson() => {
        'name': name,
        'value_string': valueString,
        'type': type.name,
      };

  factory ClixUserProperty.fromJson(Map<String, dynamic> json) => ClixUserProperty(
        name: json['name'] as String,
        valueString: json['value_string'],
        type: PropertyType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PropertyType.string,
        ),
      );
}