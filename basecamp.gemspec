require 'rubygems'

Gem::Specification.new do |gem|
  gem.name = 'basecamp'
  gem.version = '0.0.10'
  gem.summary = %Q{Basecamp API wrapper.}
  gem.description = %Q{Basecamp API wrapper.}
  gem.email = "nobody@gmail.com"
  gem.homepage = "http://github.com/anibalcucco/basecamp-wrapper"
  gem.authors = ['Anibal Cucco', 'James A. Rosen']
  
  gem.files = Dir.glob("{lib}/**/*") + %w(README.rdoc)
  
  gem.add_dependency  'oauth2'
  gem.add_dependency  'xml-simple'
  gem.add_dependency  'activeresource', '>= 2.3.0'
  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'mg',        '>= 0.0.8'
  gem.add_development_dependency 'rspec',     '>= 1.3.0'
  gem.add_development_dependency 'webmock',   '>= 1.2.2'
end
