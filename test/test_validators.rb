# require 'pry'
require 'minitest/autorun'
require 'active_record'
require 'ostruct'
require 'pathname'
require 'yaml'
require_relative '../lib/auto-seeding'

AutoSeeding::Seeder.class_eval do
  attr_reader :columns, :extra_validations
end

class TestObject # < ActiveRecord::Base
  include ActiveRecord::Validations

  FIELDS = {
    privacy:  :boolean,
    privacy2: :boolean,
    email:    :string,
    email2:   :string,
    letter:   :string,
    letter2:  :string,
    title:    :string,
    title2:   :text,
    title3:   :text,
    title4:   :text,
    title5:   :text,
    integer:  :float,
    number:   :integer,
    number2:  :float,
    number3:  :decimal,
    number4:  :integer,
    unique:   :string,
    unique2:  :integer
  }.freeze
  FIELDS_EXTRA = [:email_confirmation, :email_confirmation2].freeze
  FIELDS_SET = ( FIELDS.keys + FIELDS_EXTRA ).map { |field| ( field.to_s + '=' ).to_sym }.freeze

  validates :privacy, acceptance: true
  validates :privacy2, acceptance: { accept: true }
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
  validates :email2, confirmation: { case_sensitive: false }
  validates :letter, exclusion: { in: %w(a b c) }, length: { is: 1 }
  validates :letter2, inclusion: { in: %w(a b c) }, length: { is: 1 }
  validates :title,  length: { in: 15..20 }
  validates :title2, length: { within: 15..20 }
  validates :title3, length: { minimum: 15 }
  validates :title4, length: { maximum: 20 }
  validates :title5, length: { is: 18 }
  validates :integer, numericality: { only_integer: true }
  validates :number, numericality: true
  validates :number2, numericality: { greater_than: 15, less_than_or_equal_to: 20 }
  validates :number3, numericality: { greater_than_or_equal_to: 15, less_than: 20 }
  validates :number4, numericality: { equal_to: 18 }
  validates :unique, uniqueness: true
  validates :unique2, uniqueness: { scope: :email }

  def initialize
    @data = {}
  end

  def []( field )
    @data[field.to_sym]
  end

  def self.content_columns
    FIELDS.map do |field, type|
      OpenStruct.new( { name: field.to_s, type: type } )
    end
  end

  def self._reflections
    []
  end

protected

  def method_missing( method, *args, &block )
    if FIELDS.keys.include?( method ) || FIELDS_EXTRA.include?( method )
      self[method]
    elsif FIELDS_SET.include?( method )
      # p method
      @data[method.to_s.chop.to_sym] = args[0]
    else
      # p method
      super
    end
  end

  def respond_to?( method, include_private = false )
    FIELDS.keys.include?( method ) || FIELDS_EXTRA.include?( method ) || FIELDS_SET.include?( method ) || super
  end
end

describe 'Check validators' do
  before do
    AutoSeeding::Seeder.config  # reset global options
    @test_validators = AutoSeeding::Seeder.new
  end

  describe 'When update method is called' do
    it 'must set the validators options' do
      @test_validators.update( TestObject.new )
      cols = @test_validators.columns

      ## Validation Helpers
      # --- acceptance --------------------------------------------------------
      assert_equal cols[:privacy][:validators][:accept], ['1', true]
      assert_equal cols[:privacy2][:validators][:accept], [true]
      # --- confirmation ------------------------------------------------------
      assert_equal @test_validators.extra_validations[:confirmations], [:email, :email2]
      # --- exclusion ---------------------------------------------------------
      assert_equal cols[:letter][:validators][:not_in], ['a', 'b', 'c']
      # --- format ------------------------------------------------------------
      # TODO: not implemented
      # --- inclusion ---------------------------------------------------------
      assert_equal cols[:letter2][:validators][:in], ['a', 'b', 'c']
      # --- length ------------------------------------------------------------
      assert_equal cols[:title][:validators][:length_minimum], 15
      assert_equal cols[:title][:validators][:length_maximum], 20
      assert_equal cols[:title2][:validators][:length_minimum], 15
      assert_equal cols[:title2][:validators][:length_maximum], 20
      assert_equal cols[:title3][:validators][:length_minimum], 15
      assert_equal cols[:title4][:validators][:length_maximum], 20
      assert_equal cols[:title5][:validators][:length_minimum], 18
      assert_equal cols[:title5][:validators][:length_maximum], 18
      # --- numericality ------------------------------------------------------
      # cols[:number]  # -> set type to integer ?
      # cols[:integer] # -> set type to integer ?
      assert_equal cols[:number2][:validators][:num_gt],   15
      assert_equal cols[:number2][:validators][:num_lte],  20
      assert_equal cols[:number3][:validators][:num_gte],  15
      assert_equal cols[:number3][:validators][:num_lt],   20
      assert_equal cols[:number4][:validators][:equal_to], 18
      # --- presence ----------------------------------------------------------
      # TODO: not implemented
      # --- absence -----------------------------------------------------------
      # TODO: not implemented
      # --- uniqueness --------------------------------------------------------
      assert cols[:unique][:validators][:uniqueness]
      assert cols[:unique2][:validators][:uniqueness]
      # --- validates_with ----------------------------------------------------
      # TODO: not implemented
      # --- validates_each ----------------------------------------------------
      # TODO: not implemented
    end

    it 'must generate values respecting validations rules' do
      obj = @test_validators.update( TestObject.new )
      assert obj.privacy == '1' || obj.privacy == true
      assert obj.privacy2
      assert obj.email == obj.email_confirmation
      assert obj.email2 == obj.email2_confirmation
      assert !( ['a', 'b', 'c'].include?( obj.letter ) )
      assert ['a', 'b', 'c'].include?( obj.letter2 )
      assert obj.title.length  >= 15 && obj.title.length  <= 20
      assert obj.title2.length >= 15 && obj.title2.length <= 20
      assert obj.title3.length >= 15
      assert obj.title4.length <= 20
      assert obj.title5.length == 18
      assert obj.number2 >  15 && obj.number2 <= 20
      assert obj.number3 >= 15 && obj.number3 <  20
      assert obj.number4 == 18
    end
  end
end
