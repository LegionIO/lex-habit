# frozen_string_literal: true

require_relative 'lib/legion/extensions/habit/version'

Gem::Specification.new do |spec|
  spec.name          = 'legion-extensions-habit'
  spec.version       = Legion::Extensions::Habit::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']

  spec.summary       = 'LEX Habit'
  spec.description   = 'Procedural learning and skill acquisition for brain-modeled agentic AI — ' \
                       'repeated action sequences become chunked habits with decreasing cognitive overhead'
  spec.homepage      = 'https://github.com/LegionIO/lex-habit'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-habit'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-habit'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-habit'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-habit/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
