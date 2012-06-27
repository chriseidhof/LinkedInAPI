#
# Be sure to run `pod spec lint LinkedInAPI.podspec' to ensure this is a
# valid spec.
#
# Remove all comments before submitting the spec.
#
Pod::Spec.new do |s|
  s.name     = 'LinkedInAPI'
  s.version  = '0.0.1'
  s.license  = 'MIT'
  s.summary  = 'An example implementation of (part of) the LinkedIn API.'
  s.homepage = 'http://github.com/chriseidhof/cocoa-linkedin'
  s.author   = { 'Chris Eidhof' => 'chris@eidhof.nl' }

  s.source   = { :git => 'http://EXAMPLE/LinkedInAPI.git', :tag => '1.0.0' }

  s.platform = :ios
  s.source_files = 'LinkedInAPI.{h,m}'

  s.clean_path = "LinkedInAPI", "LinkedInAPI.xcodeproj", "Podfile"

  s.requires_arc = true

  dependency 'cocoa-oauth', :git => 'https://github.com/chriseidhof/cocoa-oauth.git'
end
