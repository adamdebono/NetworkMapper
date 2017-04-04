Pod::Spec.new do |s|
  s.name         = "NetworkMapper"
  s.version      = "0.2.0"
  s.summary      = "A framework to map JSON responses to swift objects"
  s.homepage     = "http://github.com/adamdebono/NetworkMapper"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Adam Debono" => "me@adamdebono.com" }

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/adamdebono/NetworkMapper.git", :tag => s.version }
  s.source_files  = "Source/*.swift"

  s.dependency "Alamofire", "~> 4.4.0"
  s.dependency "Unbox", "~> 2.4.0"
end
