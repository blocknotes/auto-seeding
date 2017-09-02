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
            min = @rules[:num_gte] ? @rules[:num_gte].to_f : ( @rules[:num_gt] ? ( @rules[:num_gt].to_f + 0.1 ) : MIN_FLOAT )
            max = @rules[:num_lte] ? @rules[:num_lte].to_f : ( @rules[:num_lt] ? ( @rules[:num_lt].to_f - 0.1 ) : MAX_FLOAT )
            @source_class.send( @source_method, @source_args ? eval( @source_args ) : (min .. max) )
          when :integer
            min = @rules[:num_gte] ? @rules[:num_gte].to_i : ( @rules[:num_gt] ? ( @rules[:num_gt].to_i + 1 ) : MIN_INT )
            max = @rules[:num_lte] ? @rules[:num_lte].to_i : ( @rules[:num_lt] ? ( @rules[:num_lt].to_i - 1 ) : MAX_INT )
            @source_class.send( @source_method, @source_args ? eval( @source_args ) : (min .. max) )
          when :string, :text
            @source_class.send( @source_method, *@source_args ).to_s
          else
            @source_class.send( @source_method, *@source_args )
          end
        end

      if @options[:post_process]
        post_process = eval @options[:post_process]
        value = post_process.call( value )
      end

      # validations
      case type
      when :float
        value = ( @rules[:num_gt].to_f + 0.1 ) if @rules[:num_gt] && ( value <= @rules[:num_gt].to_f )
        value = @rules[:num_gte].to_f if @rules[:num_gte] && ( value < @rules[:num_gte].to_f )
        value = ( @rules[:num_lt].to_f - 0.1 ) if @rules[:num_lt] && ( value >= @rules[:num_lt].to_f )
        value = @rules[:num_lte].to_f if @rules[:num_lte] && ( value > @rules[:num_lte].to_f )
      when :integer
        value = ( @rules[:num_gt].to_i + 1 ) if @rules[:num_gt] && ( value <= @rules[:num_gt].to_i )
        value = @rules[:num_gte].to_i if @rules[:num_gte] && ( value < @rules[:num_gte].to_i )
        value = ( @rules[:num_lt].to_i - 1 ) if @rules[:num_lt] && ( value >= @rules[:num_lt].to_i )
        value = @rules[:num_lte].to_i if @rules[:num_lte] && ( value > @rules[:num_lte].to_i )
      when :string, :text
        value = value.ljust( @rules[:length_minimum], '-' ) if @rules[:length_minimum]
        value = value.slice( 0..( @rules[:length_maximum] - 1 ) ) if @rules[:length_maximum]
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
