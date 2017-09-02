# require 'pry'
require 'minitest/autorun'
require 'ostruct'
require 'pathname'
require 'yaml'
require_relative '../lib/auto-seeding'

# class TestObject
#   # def initialize
#   #   super
#   # end

#   def self.content_columns
#     [OpenStruct.new({
#       name: 'test',
#     })]
#   end

#   def self._reflections
#     []
#   end

#   def self._validators
#     {
#       test: []
#     }
#   end
# end

describe 'AutoSeeding basic' do
  before do
    @auto_seeding = AutoSeeding::Seeder.new
  end

  describe 'When generating a value of any type' do
    it 'must return a correct value' do
      @auto_seeding.sources[:types].each do |type, data|
        value = AutoSeeding::Source.new( :test1, type, nil, data ).gen
        case type
        when :boolean
          assert( value.is_a?( FalseClass ) || value.is_a?( TrueClass ) )
        when :date
          assert_instance_of( Date, value )
        when :datetime, :timestamp
          assert_instance_of( DateTime, value )
        when :float, :decimal
          assert_instance_of( Float, value )
        when :integer
          assert_instance_of( Fixnum, value )
        when :string, :text
          assert_instance_of( String, value )
          v = value.strip
          assert( v.length > 0 )
          assert( !v.empty? )
        when :time
          assert_instance_of( Time, value )
        else
          assert( false, "Invalid type: #{type}" )
        end
      end
    end
  end
end
