# frozen_string_literal: true

require_relative 'lib/enum_errors_away/version'

Gem::Specification.new do |spec|
  spec.name          = 'enum_errors_away'
  spec.version       = EnumErrorsAway::VERSION
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']

  spec.summary       = 'Fix Rails 7.2+ enum migration failures'
  spec.description   = 'Eliminates "Undeclared attribute type for enum" errors that occur when running ' \
                       'migrations with multiple enum columns added in separate migrations. Automatically ' \
                       'declares missing enum attributes as integers, preventing migration failures.'
  spec.homepage      = 'https://github.com/yourusername/enum_errors_away'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Note: sig/ directory is intentionally excluded from distribution to avoid conflicts with user's type definitions
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{lib,sig}/**/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md'].reject do |f|
      f.start_with?('sig/dev/') || !File.file?(f)
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 6.0'
  spec.add_dependency 'rails', '>= 6.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-reporters', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'sqlite3', '>= 2.1'
end
