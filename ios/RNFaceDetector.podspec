Pod::Spec.new do |s|
  s.name             = 'RNFaceDetector'
  s.version          = '0.0.1'
  s.summary          = 'React Native Firebase MLKit Face Detection'
  s.description      = <<-DESC
  Firebase MLKit Face Detection implementation for React Native
                       DESC
  s.homepage         = 'https://github.com/wowmaking/react-native-face-detector.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qvick1pro' => 'g.volchetskiy@wowmaking.net' }
  s.source           = { :git => 'https://github.com/wowmaking/react-native-face-detector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.swift_version = '3.0'

  s.source_files = 'RNFaceDetector/**/*'

  s.static_framework = true
  
  s.dependency 'React'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/MLVision'
  s.dependency 'Firebase/MLVisionFaceModel'
end
