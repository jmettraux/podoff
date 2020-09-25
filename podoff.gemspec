
Gem::Specification.new do |s|

  s.name = 'podoff'

  s.version = File.read(
    File.expand_path('../lib/podoff.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'https://github.com/jmettraux/podoff'
  s.license = 'MIT'
  s.summary = 'a tool to deface PDF documents'

  s.description = %{
A library to write over existing PDF documents
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'README.{md,txt}',
    'CHANGELOG.{md,txt}', 'CREDITS.{md,txt}', 'LICENSE.{md,txt}',
    'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    "#{s.name}.gemspec",
  ]

  #s.add_runtime_dependency 'tzinfo'

  s.add_development_dependency 'rspec', '~> 3.7'

  s.require_path = 'lib'
end

