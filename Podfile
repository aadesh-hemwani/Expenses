# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'Expenses' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks! :linkage => :static

  # Pods for Expenses
  pod 'Firebase/Auth'
  pod 'GoogleSignIn'
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
        
        if target.name == 'leveldb-library'
            config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++14'
            config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
            config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
        end

        if target.name == 'RecaptchaInterop'
            config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
        end
      end
    end
  end
end
