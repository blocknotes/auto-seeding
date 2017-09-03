require 'auto-seeding/utils'
require 'auto-seeding/source'
require 'auto-seeding/seeder'

module AutoSeeding
  NAME = 'auto-seeding'.freeze
  DATE = '2017-08-28'.freeze
  INFO = 'Auto seeding component for ActiveRecord'.freeze
  DESC = 'A component to auto generate seed data with ActiveRecord using a set of predefined or custom rules respecting models validations'.freeze
  AUTHORS = [ [ 'Mattia Roccoberton', 'mat@blocknot.es', 'http://blocknot.es' ] ].freeze
  VERSION = [ 0, 1, 2 ].freeze
end
