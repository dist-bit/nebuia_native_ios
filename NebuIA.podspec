Pod::Spec.new do |s|
  s.name          = "NebuIA"
  s.version       = "0.0.18"
  s.summary       = "iOS SDK for NebuIA"
  s.description   = "iOS SDK for NebuIA SDK"
  s.homepage      = "https://github.com/dist-bit/nebuia_native_ios"
  s.license       = "MIT"
  s.author        = "xellDart"
  s.platform      = :ios, "12.0"
  s.swift_version = "5.4.1"
  s.source        = {
    :git => "https://github.com/dist-bit/nebuia_native_ios.git",
    :tag => "#{s.version}"
  }
  s.vendored_frameworks = 'ncnn.framework', 'openmp.framework', 'libc++.tbd'
  s.source_files        = "NebuIA/**/*.{h,m,mm,swift}"
  s.resources = "Assets/*"
  s.public_header_files = "NebuIA/**/*.h"
  s.dependency 'Cartography', '~> 3.0'
  s.dependency 'SDWebImageWebPCoder'
  s.info_plist = { 'CFBundleIdentifier' => 'com.distbit.NebuIA' }
  s.static_framework = true
end