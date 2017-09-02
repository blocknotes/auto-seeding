# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path( '../lib/', __FILE__ )
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?( lib )
require 'auto-seeding'

Gem::Specification.new do |spec|
  spec.name        = AutoSeeding::NAME
  spec.version     = AutoSeeding::VERSION.join('.')
  spec.date        = AutoSeeding::DATE
  spec.summary     = AutoSeeding::INFO
  spec.description = AutoSeeding::DESC
  spec.authors     = AutoSeeding::AUTHORS.map { |a| a[0] }.flatten
  spec.email       = AutoSeeding::AUTHORS.first[1]
  spec.files       = ['lib/auto-seeding.rb']
  spec.homepage    = 'https://github.com/blocknotes/auto-seeding'
  spec.license     = 'MIT'
  spec.add_development_dependency 'activerecord', '~> 5'
  spec.add_development_dependency 'minitest', '~> 5'
end
