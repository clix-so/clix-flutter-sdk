import 'package:json_annotation/json_annotation.dart';

part 'clix_user_property.g.dart';

enum PropertyType {
  @JsonValue('USER_PROPERTY_TYPE_STRING')
  string,
  @JsonValue('USER_PROPERTY_TYPE_NUMBER')
  number,
  @JsonValue('USER_PROPERTY_TYPE_BOOLEAN')
  boolean;
}

@JsonSerializable()
class ClixUserProperty {
  final String name;
  @JsonKey(name: 'value_string')
  final dynamic valueString;
  final PropertyType type;

  const ClixUserProperty({
    required this.name,
    required this.valueString,
    required this.type,
  });

  factory ClixUserProperty.of({required String name, required dynamic value}) {
    PropertyType type;
    dynamic codableValue;

    if (value is bool) {
      type = PropertyType.boolean;
      codableValue = value;
    } else if (value is num) {
      type = PropertyType.number;
      codableValue = value;
    } else if (value is String) {
      type = PropertyType.string;
      codableValue = value;
    } else {
      type = PropertyType.string;
      codableValue = value.toString();
    }

    return ClixUserProperty(
      name: name,
      valueString: codableValue,
      type: type,
    );
  }

  Map<String, dynamic> toJson() => _$ClixUserPropertyToJson(this);

  factory ClixUserProperty.fromJson(Map<String, dynamic> json) =>
      _$ClixUserPropertyFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixUserProperty &&
        other.name == name &&
        other.valueString == valueString &&
        other.type == type;
  }

  @override
  int get hashCode => name.hashCode ^ valueString.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'ClixUserProperty(name: $name, value: $valueString, type: ${type.name})';
  }
}
