import 'package:json_annotation/json_annotation.dart';

part 'clix_user_property.g.dart';

/// Property type enumeration matching iOS SDK
enum PropertyType {
  @JsonValue('USER_PROPERTY_TYPE_STRING')
  string('USER_PROPERTY_TYPE_STRING'),
  @JsonValue('USER_PROPERTY_TYPE_NUMBER')
  number('USER_PROPERTY_TYPE_NUMBER'),
  @JsonValue('USER_PROPERTY_TYPE_BOOLEAN')
  boolean('USER_PROPERTY_TYPE_BOOLEAN');

  const PropertyType(this.value);
  final String value;

  static PropertyType fromString(String value) {
    switch (value) {
      case 'USER_PROPERTY_TYPE_STRING':
        return PropertyType.string;
      case 'USER_PROPERTY_TYPE_NUMBER':
        return PropertyType.number;
      case 'USER_PROPERTY_TYPE_BOOLEAN':
        return PropertyType.boolean;
      default:
        throw ArgumentError('Unknown property type: $value');
    }
  }
}

/// User property model for Clix SDK
/// Supports string, number, and boolean property types
@JsonSerializable(fieldRename: FieldRename.snake)
class ClixUserProperty {
  final String name;
  @JsonKey(name: 'value_string')
  final dynamic value;
  final PropertyType type;

  const ClixUserProperty({
    required this.name,
    required this.value,
    required this.type,
  });

  /// Create user property from value (auto-detect type)
  factory ClixUserProperty.fromValue(String name, dynamic value) {
    PropertyType type;

    if (value is String) {
      type = PropertyType.string;
    } else if (value is num) {
      type = PropertyType.number;
    } else if (value is bool) {
      type = PropertyType.boolean;
    } else {
      // Convert to string for unsupported types
      type = PropertyType.string;
      value = value.toString();
    }

    return ClixUserProperty(
      name: name,
      value: value,
      type: type,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => _$ClixUserPropertyToJson(this);

  /// Create from JSON
  factory ClixUserProperty.fromJson(Map<String, dynamic> json) =>
      _$ClixUserPropertyFromJson(json);

  /// Get the actual typed value
  T? getValue<T>() {
    if (value is T) {
      return value as T;
    }

    // Try to convert based on type
    switch (type) {
      case PropertyType.string:
        try {
          return value.toString() as T;
        } catch (_) {
          return null;
        }
      case PropertyType.number:
        if (T == int) {
          return (value is num
              ? value.toInt()
              : int.tryParse(value.toString()) ?? 0) as T?;
        } else if (T == double) {
          return (value is num
              ? value.toDouble()
              : double.tryParse(value.toString()) ?? 0.0) as T?;
        }
        try {
          return value as T;
        } catch (_) {
          return null;
        }
      case PropertyType.boolean:
        if (T == bool) {
          if (value is bool) return value as T;
          if (value is String) {
            return (value.toLowerCase() == 'true') as T;
          }
          return (value == 1) as T;
        }
        try {
          return value as T;
        } catch (_) {
          return null;
        }
    }
  }

  /// Validate that the value matches the declared type
  bool get isValid {
    switch (type) {
      case PropertyType.string:
        return value is String;
      case PropertyType.number:
        return value is num;
      case PropertyType.boolean:
        return value is bool;
    }
  }

  @override
  String toString() {
    return 'ClixUserProperty(name: $name, value: $value, type: ${type.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixUserProperty &&
        other.name == name &&
        other.value == value &&
        other.type == type;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode ^ type.hashCode;
}

/// Helper class for managing multiple user properties
class ClixUserProperties {
  final Map<String, ClixUserProperty> _properties = {};

  ClixUserProperties();

  /// Add or update a user property
  void setProperty(String name, dynamic value) {
    _properties[name] = ClixUserProperty.fromValue(name, value);
  }

  /// Get a property by name
  ClixUserProperty? getProperty(String name) {
    return _properties[name];
  }

  /// Get property value by name
  T? getPropertyValue<T>(String name) {
    final property = _properties[name];
    return property?.getValue<T>();
  }

  /// Remove a property
  void removeProperty(String name) {
    _properties.remove(name);
  }

  /// Remove multiple properties
  void removeProperties(List<String> names) {
    for (final name in names) {
      _properties.remove(name);
    }
  }

  /// Clear all properties
  void clear() {
    _properties.clear();
  }

  /// Get all property names
  List<String> get propertyNames => _properties.keys.toList();

  /// Get all properties
  List<ClixUserProperty> get properties => _properties.values.toList();

  /// Check if property exists
  bool hasProperty(String name) => _properties.containsKey(name);

  /// Get property count
  int get count => _properties.length;

  /// Check if empty
  bool get isEmpty => _properties.isEmpty;

  /// Check if not empty
  bool get isNotEmpty => _properties.isNotEmpty;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'properties': _properties.values.map((p) => p.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory ClixUserProperties.fromJson(Map<String, dynamic> json) {
    final instance = ClixUserProperties();
    final propertiesList = json['properties'] as List<dynamic>? ?? [];

    for (final propJson in propertiesList) {
      if (propJson is Map<String, dynamic>) {
        final property = ClixUserProperty.fromJson(propJson);
        instance._properties[property.name] = property;
      }
    }

    return instance;
  }

  /// Convert to simple map for storage
  Map<String, dynamic> toMap() {
    return Map.fromEntries(
      _properties.entries.map((e) => MapEntry(e.key, e.value.value)),
    );
  }

  /// Create from simple map
  factory ClixUserProperties.fromMap(Map<String, dynamic> map) {
    final properties = ClixUserProperties();
    for (final entry in map.entries) {
      properties.setProperty(entry.key, entry.value);
    }
    return properties;
  }

  @override
  String toString() {
    return 'ClixUserProperties(count: $count, properties: ${_properties.keys.toList()})';
  }
}
