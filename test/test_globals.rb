require 'minitest/autorun'
require 'ostruct'
require 'pathname'
# require 'pry'
require 'yaml'
require 'ffaker'
require_relative '../lib/auto-seeding'

describe 'AutoSeeding global config' do
  before do
    AutoSeeding::Seeder.config({
      skip_associations: [:versions],
      conf: {
        seeder: :ffaker,
      },
    })
  end

  describe 'When using config method' do
    it 'must merge the internal options' do
      auto_seeding = AutoSeeding::Seeder.new
      # p auto_seeding.sources
      # p auto_seeding.options
      assert_equal( auto_seeding.options[:conf][:seeder], :ffaker )
      auto_seeding2 = AutoSeeding::Seeder.new
      assert_equal( auto_seeding.options[:conf][:seeder], :ffaker )
    end
  end
end
