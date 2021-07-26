# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'accesstype_adyen/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = 'accesstype_adyen'
  spec.version = AccesstypeAdyen::VERSION
  spec.authors = ['Vesa Pöyhönen']
  spec.email = ['vesa.poyhonen@gmail.com']
  spec.homepage = 'https://github.com/vesa-poyhonen/accesstype_adyen'
  spec.summary = 'A wrapper for Adyen APIs'
  spec.description = 'This gem will be used for calling Adyen API'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/vesa-poyhonen/accesstype_adyen'
  spec.metadata['changelog_uri'] = 'https://github.com/vesa-poyhonen/accesstype_adyen/CHANGELOG.md'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'none'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'webmock', '~> 2.1'
  spec.add_dependency 'httparty', '~> 0.13.7'
end
