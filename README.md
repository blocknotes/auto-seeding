# Auto-seeding [![Gem Version](https://badge.fury.io/rb/auto-seeding.svg)](https://badge.fury.io/rb/auto-seeding) [![Build Status](https://travis-ci.org/blocknotes/auto-seeding.svg)](https://travis-ci.org/blocknotes/auto-seeding)

A component to auto generate seed data with ActiveRecord using a set of predefined or custom rules respecting models validations.

## Install

- Add to Gemfile: `gem 'auto-seeding'` (better in *development* group)
- Edit the seed task:

```rb
auto_seeding = AutoSeeding::Seeder.new
3.times.each do
  auto_seeding.update( Author.new ).save!
end
```

### Options

- **conf/seeder**: seeding source [*nil* | *:faker* | *:ffaker*] (*:faker* requires Faker gem, *:ffaker* requires FFaker gem)
- **conf/file**: load seed configuration from a local file
- **auto_create**: array of nested associations to create while seeding, ex. [*:profile*],
- **ignore_attrs**: ignore some attributes, ex. [*:id*, *updated_at*]
- **skip_associations**: array of nested associations to skip while seeding, ex. [*:posts*]
- **sources**: configure sources rules for autoseed data

Conf file: see [data folder](https://github.com/blocknotes/auto-seeding/tree/master/lib/auto-seeding/data)

Global options (shared between instances):

```rb
AutoSeeding::Seeder.config({
  skip_associations: [:versions],
  conf: {
    seeder: :ffaker,
  },
})
```

Instance options:

```rb
autoseeding = AutoSeeding::Seeder.new({
  auto_create: [:profile],       # array of symbols
  conf: {
    file: 'test/conf.yml',       # string
    seeder: :faker,              # symbol - :faker or :ffaker
  },
  ignore_attrs: [:id],           # array of symbols - ignored attributes
  skip_associations: [:author],  # array of symbols - ignored nested associations
  sources: {                     # hash - keys: types, fields
    types: {                     # hash - override basic types rules
      integer: {
        source_model: 'Random',
        source_method: 'rand',
        source_args: '0..100',
      }
    },
    fields: [                    # array of hashes - override fields rules
      {
        in: ['name'],
        source_model: 'Faker::Hipster',
        source_method: 'word',
        type: 'string'
      },
      {
        regexp: '^(.+_|)title(|_.+)$',
        source_model: 'Faker::Hipster',
        source_method: 'word',
        post_process: '->( val ) { val + " (seeding)" }',
        type: 'string'
      }
    ]
  }
})
```

## Notes

Generated data can be manipulated easily before saving:

```rb
obj = auto_seeding.update( Author.new )
obj.name = 'John Doe'
obj.save!
```

Field names can be changed using *append* and *prepend* options - example using Carrierwave remote url property:

```rb
AutoSeeding::Seeder.new({
  sources: {
    fields: [
      {
        regexp: '^(.+_|)photo(|_.+)$|^(.+_|)image(|_.+)$',
        source_model: 'Faker::Avatar',
        source_method: 'image',
        prepend: 'remote_',
        append: '_url',
        type: 'string'
      }
    ]
  }
}
```

## Contributors

- [Mattia Roccoberton](http://blocknot.es) - creator, maintainer

## License

[MIT](LICENSE.txt)
