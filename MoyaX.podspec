Pod::Spec.new do |s|
  s.name        = "MoyaX"
  s.version     = "0.0.2"
  s.summary     = "Network abstraction layer written in Swift, it's a fork of Moya"
  s.description = <<-EOS
  MoyaX abstracts network commands using Swift Generics to provide developers
  with more compile-time confidence.

  ReactiveCocoa and RxSwift extensions exist as well. Instructions for installation
  are in [the README](https://github.com/jasl/MoyaX).
  EOS
  s.homepage                  = "https://github.com/jasl/MoyaX"
  s.license                   = { :type => "MIT", :file => "License.md" }
  s.author                    = { "jasl" => "jasl9187@hotmail", "Ash Furrow" => "ash@ashfurrow.com" }
  s.social_media_url          = "http://twitter.com/jasl9187"
  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'
  s.source                    = { :git => "https://github.com/jasl/MoyaX.git", :tag => s.version }
  s.default_subspec           = "Core"

  s.subspec "Core" do |ss|
    ss.source_files  = %w(Source/*.swift Source/Plugins/*.swift Source/Backends/*.swift)
    ss.framework     = "Foundation"
    ss.dependency "Alamofire", "~> 3.0"
    ss.dependency "Result", "~> 1.0"
  end

  s.subspec "ReactiveCocoa" do |ss|
    ss.source_files = %w(Source/ReactiveCocoa/*.swift)
    ss.dependency "MoyaX/Core"
    ss.dependency "ReactiveCocoa", "~> 4.0"
  end

  s.subspec "RxSwift" do |ss|
    ss.source_files = %w(Source/RxSwift/*.swift)
    ss.dependency "MoyaX/Core"
    ss.dependency "RxSwift", "~> 2.0"
  end
end
