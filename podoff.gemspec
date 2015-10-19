
Gem::Specification.new do |s|

  s.name = 'podoff'

  s.version = File.read(
    File.expand_path('../lib/podoff.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://github.com/jmettraux/podoff'
  s.rubyforge_project = 'rufus'
  s.license = 'MIT'
  s.summary = 'a tool to deface PDF documents'

  s.description = %{
a tool to deface PDF documents
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  #s.add_runtime_dependency 'tzinfo'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.13.0'

  s.require_path = 'lib'
end

