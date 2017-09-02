# coding: utf-8
module AutoSeeding
  class Seeder
    TYPES = [:boolean, :date, :datetime, :float, :decimal, :integer, :string, :text, :time, :timestamp]

    attr_reader :options, :sources

    @@globals = { conf: {}, sources: {} }

    def initialize( opts = {} )
      options = { conf: @@globals[:conf], sources: @@globals[:sources] }
      AutoSeeding::_deep_merge!( options, opts )

      @columns = {}
      @models = {}
      @extra_validations = { confirmations: [] }
      options[:ignore_attrs] ||= [:id, :created_at, :updated_at]
      options[:ignore_attrs] += @@globals[:ignore_attrs] if @@globals[:ignore_attrs]
      options[:skip_associations] ||= []
      options[:skip_associations] += @@globals[:skip_associations] if @@globals[:skip_associations]

      path = options[:conf][:file]
      if path
        options[:conf].delete :seeder
      else
        yml_file = if options[:conf][:seeder] == :ffaker
            puts 'warning: seeder set to ffaker but FFaker is not available' unless defined? FFaker
            'ffaker.yml'
          elsif options[:conf][:seeder] == :faker
            puts 'warning: seeder set to faker but Faker is not available' unless defined? Faker
            'faker.yml'
          else
            'basic.yml'
          end
        path = Pathname.new( File.dirname __FILE__ ).join( 'data', yml_file ).to_s
      end

      # Random.srand( options[:conf][:seed_number] ? options[:conf][:seed_number].to_i : Random.new_seed )  # NOTE: problems here

      yml = Seeder::symbolize_keys YAML.load_file( path )
      # @sources = yml[:sources].merge( options[:sources] ? options[:sources] : {} )
      @sources = yml[:sources].dup
      AutoSeeding::_deep_merge!( @sources, options[:sources] ) if options[:sources]
      @sources[:fields] ||= {}
      @sources[:fields].map! { |s| Seeder::symbolize_keys s }
      @sources[:fields].sort! { |a, b| ( a['model'] || a[:model] ) ? -1 : ( ( b['model'] || b[:model] ) ? 1 : 0 ) }
      @options = options

      self
    end

    def update( object )
      model = object.class

      model.content_columns.each do |column|
        col = column.name.to_sym
        next if @options[:ignore_attrs].include? col
        @columns[col] ||= {
          validators: prepare_validators( model._validators[col] )
        }

        found = false
        @sources[:fields].each do |f|
          if f[:model]
            next unless Regexp.new( f[:model], Regexp::IGNORECASE ).match( model.to_s )
          end
          if( f[:in] && f[:in].include?( col.to_s ) ) ||
            ( f[:regexp] && Regexp.new( f[:regexp], Regexp::IGNORECASE ).match( col.to_s ) )
            col_ = ( f[:prepend] || f[:append] ) ? ( f[:prepend].to_s + col.to_s + f[:append].to_s ) : col.to_s
            @columns[col][:src] ||= Source.new( col, f[:type] ? f[:type].to_sym : :string, @columns[col][:validators], f )
            object.send( col_ + '=', @columns[col][:src].gen )
            found = true
            break
          end
        end
        next if found

        if TYPES.include? column.type
          object.send( col.to_s + '=', ( @columns[col][:src] ||= Source.new( col, column.type, @columns[col][:validators], @sources[:types][column.type] ) ).gen )
        end
      end

      # Setup associations
      model._reflections.each do |association, data|
        next if @options[:skip_associations].include? association.to_sym
        model2 = data.klass
        if @options[:auto_create] && @options[:auto_create].include?( association.to_sym )
          auto_seeding = AutoSeeding::Seeder.new( { conf: { seeder: @options[:seeder] }, skip_associations: [model.to_s.underscore.to_sym] } )
          object.send( association + '=', auto_seeding.update( model2.new ) )
        else
          @models[model2.table_name] ||= model2.all
          sam = @models[model2.table_name].sample
          object.send( association + '=', sam ) if sam
        end
      end

      # Extra validations
      @extra_validations[:confirmations].each do |field|
        object.send field.to_s+'_confirmation=', object[field]
      end

      object
    end

    def self.config( options = nil )
      @@globals = options ? options : { conf: {}, sources: {} }
    end

  protected

    def prepare_validators( validators )
      ret = {}
      validators.each do |validator|
        case validator.class.name.split( '::' ).last
        when 'AcceptanceValidator'
          ret[:accept] = validator.options[:accept]
        when 'ConfirmationValidator'
          # ret[:confirmation] = validator.options[:confirmation]
          @extra_validations[:confirmations] += validator.attributes
          # case_sensitive - TODO: not implemented
        when 'ExclusionValidator'
          ret[:not_in] = validator.options[:in] # TODO: not implemented
        when 'InclusionValidator'
          ret[:in] = validator.options[:in]
        when 'LengthValidator'
          if validator.options[:is]
            ret[:length_minimum] = validator.options[:is]
            ret[:length_maximum] = validator.options[:is]
          else
            ret[:length_minimum] = validator.options[:minimum]
            ret[:length_maximum] = validator.options[:maximum]
          end
        when 'NumericalityValidator'
          ret[:num_gt] = validator.options[:greater_than]
          ret[:num_gte] = validator.options[:greater_than_or_equal_to]
          ret[:equal_to] = validator.options[:equal_to]
          ret[:num_lt] = validator.options[:less_than]
          ret[:num_lte] = validator.options[:less_than_or_equal_to]
          # ret[:other_than] = validator.options[:other_than] # TODO: not implemented
          # ret[:odd] = validator.options[:odd]               # TODO: not implemented
          # ret[:even] = validator.options[:even]             # TODO: not implemented
        when 'PresenceValidator'
          # ret[:presence] = true # TODO: not implemented
        when 'UniquenessValidator'
          ret[:uniqueness] = true
        else
          # p validator.class.name.split( '::' ).last # DEBUG
        end
      end
      ret
    end

    def self.symbolize_keys( obj )
      if obj.is_a?( Hash )
        obj2 ||= {}
        obj.each do |k, v|
          obj2[k.to_sym] = symbolize_keys( v )
        end
        return obj2
      end
      obj
    end
  end
end
