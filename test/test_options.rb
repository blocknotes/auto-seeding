# require 'pry'
require 'minitest/autorun'
require 'ostruct'
require 'pathname'
require 'yaml'
require_relative '../lib/auto-seeding'

describe 'AutoSeeding Options' do
  before do
    AutoSeeding::Seeder.config  # reset global options
    @test_options = AutoSeeding::Seeder.new({
      auto_create: [:profile],       # array of symbols - nested associations to create while seeding
      conf: {
        file: 'test/conf.yml',       # string - local seed configuration file
        seeder: :faker,              # symbol - :faker or :ffaker
      },
      ignore_attrs: [:id],           # array of symbols - ignored attributes
      skip_associations: [:author],  # array of symbols - ignored nested associations
      sources: {                     # hash - keys: types, fields
        types: {                     # hash - override basic types rules
          integer: {
            source_model: Random,
            source_method: 'rand',
            source_args: 0..100,
          }
        },
        # fields: [                    # array of hashes - overried fields rules
        #   {
        #     in: ['name'],
        #     source_model: 'Faker::Hipster',
        #     source_method: 'word',
        #     type: 'string'
        #   }
        # ]
      }
    })
  end

  describe 'When using constructor options hash' do
    it 'must merge the internal options' do
      assert_nil( @test_options.options[:conf][:seeder] ) # overriden by file option
      assert_equal( @test_options.options[:auto_create], [:profile] )
      assert_equal( @test_options.options[:ignore_attrs], [:id] )
      assert_equal( @test_options.options[:skip_associations], [:author] )
      assert_equal( @test_options.sources[:fields][0][:source_args], 1 )
      assert_equal( @test_options.sources[:types].keys, [:integer] )
    end
  end
end
