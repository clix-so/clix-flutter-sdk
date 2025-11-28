import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/platform/messages.g.dart',
    dartOptions: DartOptions(
      copyrightHeader: [
        'coverage:ignore-file',
        'ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers, unused_element',
      ],
    ),
    swiftOut: 'ios/Classes/Messages.g.swift',
    kotlinOut: 'android/src/main/kotlin/so/clix/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'so.clix'),
  ),
)
@HostApi()
abstract class ClixHostApi {}

@FlutterApi()
abstract class ClixFlutterApi {
  void onNotificationTapped(Map<String?, Object?> userInfo);
}
