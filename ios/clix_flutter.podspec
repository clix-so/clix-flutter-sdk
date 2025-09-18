#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint clix_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'clix_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter SDK for Clix service - customer engagement platform'
  s.description      = <<-DESC
Flutter SDK for Clix service that provides customer engagement features including
push notifications, user tracking, and analytics with Firebase integration.
                       DESC
  s.homepage         = 'https://clix.so'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Clix' => 'support@clix.so' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.ios.deployment_target = '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_VERSION' => '5.0'
  }
  s.swift_version = '5.0'
end