Pod::Spec.new do |s|
  s.name        = 'MoyaX'
  s.version     = '0.0.1'
  s.summary     = "Network abstraction layer written in Swift, it's a fork of Moya"
  s.description = <<-EOS
                  MoyaX abstracts network commands using Swift Generics to provide developers
                  with more compile-time confidence.
                  EOS
  s.homepage         = 'https://github.com/jasl/MoyaX'
  s.license          = {type: 'MIT', file: 'License.md'}
  s.author           = {'jasl' => 'jasl9187@hotmail', 'Ash Furrow' => 'ash@ashfurrow.com'}
  s.social_media_url = 'http://twitter.com/jasl9187'
  s.source           = {git: 'https://github.com/jasl/MoyaX.git', tag: s.version }

  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'

  s.framework = 'Foundation'

  s.dependency 'Alamofire', '~> 3.0'

  s.source_files = 'Sources/**/*.swift'
end
