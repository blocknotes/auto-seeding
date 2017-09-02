# coding: utf-8
module AutoSeeding
  class Source
    DAY_SECONDS = ( 60 * 60 * 24 )
    MIN_INT = 0
    MAX_INT = 1_000_000
    MIN_FLOAT = 0.0
    MAX_FLOAT = 1000.0
    MONTH_SECONDS = ( DAY_SECONDS * 30 ).freeze
    VOWELS = %w(a e i o u).freeze
    CONSONANTS = (('a'..'z').to_a - VOWELS).freeze

    def initialize( column, type, rules, options = {} )
      @column = column
      @type = type
      @rules = rules ? rules : {}
      @options = options || {}
      if @options[:source_model] && @options[:source_method]
        @source_class  = Object.const_get @options[:source_model]
        @source_method = @options[:source_method].to_sym
        @source_args   = @options[:source_args]
      else
        @source_class  = AutoSeeding::Source
        @source_method = :random_string
        @source_args = nil
      end
      @uniqueness = {}
      self
    end

    def gen
      @retry = 100
      process @type
    end

    def self.random_boolean
      [false, true].sample
    end

    def self.random_string( words = 10 )
      (1..rand(words)+1).map do
        (0..rand(10)+1).map do |i|
          i % 2 == 0 ? CONSONANTS.sample : VOWELS.sample
        end.join
      end.join( ' ' ).capitalize
    end

  protected

    def process( type = nil )
      value =
        if @rules[:equal_to]
          @rules[:equal_to]
        elsif @rules[:in]
          @rules[:in].sample
        elsif @rules[:accept]
          @rules[:accept].sample
        else
          case type
          when :float
            min = @rules[:greater_than_or_equal_to] ? @rules[:greater_than_or_equal_to].to_f : ( @rules[:greater_than] ? ( @rules[:greater_than].to_f - 1 ) : MIN_FLOAT )
            max = @rules[:less_than_or_equal_to] ? @rules[:less_than_or_equal_to].to_f : ( @rules[:less_than] ? ( @rules[:less_than].to_f - 1 ) : MAX_FLOAT )
            @source_class.send( @source_method, @source_args ? eval( @source_args ) : (min .. max) )
          when :integer
            min = @rules[:greater_than_or_equal_to] ? @rules[:greater_than_or_equal_to].to_i : ( @rules[:greater_than] ? ( @rules[:greater_than].to_i - 1 ) : MIN_INT )
            max = @rules[:less_than_or_equal_to] ? @rules[:less_than_or_equal_to].to_i : ( @rules[:less_than] ? ( @rules[:less_than].to_i - 1 ) : MAX_INT )
            @source_class.send( @source_method, @source_args ? eval( @source_args ) : (min .. max) )
          when :string
            v = @source_class.send( @source_method, *@source_args ).to_s
            v = v.ljust( @rules[:minimum], '-' ) if @rules[:minimum]
            v = v.slice( 0..( @rules[:maximum] - 1 ) ) if @rules[:maximum]
            v
          when :time
            @source_class.send( @source_method, *@source_args ).to_time
          # when :date
          # when :boolean
          else
            @source_class.send( @source_method, *@source_args )
          end
        end

      if @options[:post_process]
        post_process = eval @options[:post_process]
        value = post_process.call( value )
      end

      if @rules[:not_in] && @rules[:not_in].include?( value )
        @retry -= 1
        return @retry > 0 ? process( type ) : raise( Exception.new( 'Reserved value' ) )
      end

      if @rules[:uniqueness]
        @uniqueness[@column] ||= {}
        if @uniqueness[@column].has_key?( value )
          return ( @retry -= 1 ) > 0 ? process( type ) : raise( Exception.new( 'Value already taken' ) )
        else
          @uniqueness[@column][value] = true
        end
      end

      value
    end
  end
end
