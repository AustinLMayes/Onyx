Gem::Specification.new do |s|
    s.name        = "onyx"
    s.version     = "1.0"
    s.platform    = Gem::Platform::RUBY
    s.authors     = ["Austin Mayes"]
    s.summary     = "API for working with data from Onyx showfiles"
  
    s.required_rubygems_version = ">= 1.3.6"
  
    s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
    s.require_path = 'lib'
  end