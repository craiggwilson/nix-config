# Ruby Search Patterns

## Definitions

```bash
# Find class definitions
rg -n "^class \w+" --type ruby

# Find module definitions
rg -n "^module \w+" --type ruby

# Find method definitions
rg -n "^\s*def \w+" --type ruby

# Find class method definitions
rg -n "^\s*def self\.\w+" --type ruby

# Find attr_accessor/reader/writer
rg -n "attr_(accessor|reader|writer)" --type ruby

# Find constant definitions
rg -n "^\s*[A-Z][A-Z_]+ =" --type ruby
```

## Usages

```bash
# Find require statements
rg -n "^require " --type ruby

# Find require_relative
rg -n "^require_relative " --type ruby

# Find gem dependencies
rg -n "^gem " Gemfile

# Find method calls
rg -n "\.method_name" --type ruby
```

## Patterns

```bash
# Find Rails concerns
rg -n "extend ActiveSupport::Concern" --type ruby

# Find Rails callbacks
rg -n "before_action|after_action|around_action" --type ruby
rg -n "before_save|after_save|before_create" --type ruby

# Find Rails validations
rg -n "validates " --type ruby

# Find Rails associations
rg -n "has_many|has_one|belongs_to|has_and_belongs_to_many" --type ruby

# Find Rails scopes
rg -n "scope :\w+" --type ruby

# Find blocks
rg -n "do \|.*\||{ \|.*\|" --type ruby

# Find metaprogramming
rg -n "define_method|method_missing|class_eval|instance_eval" --type ruby
```

## Entry Points

```bash
# Find Rails controllers
rg -n "class \w+Controller < " --type ruby

# Find Rails models
rg -n "class \w+ < ApplicationRecord" --type ruby

# Find Rails routes
rg -n "resources |get |post |put |delete |patch " config/routes.rb

# Find Rake tasks
rg -n "task :\w+" --type ruby

# Find Sidekiq workers
rg -n "include Sidekiq::Worker" --type ruby

# Find CLI commands
rg -n "Thor|GLI|Commander" --type ruby
```

## Testing

```bash
# Find RSpec describe blocks
rg -n "RSpec\.describe|describe " --type ruby

# Find test methods
rg -n "it ['\"]|context ['\"]" --type ruby

# Find test files
fd "_spec.rb$"
fd "_test.rb$"

# Find factories
rg -n "FactoryBot\.define|factory :\w+" --type ruby

# Find shared examples
rg -n "shared_examples|it_behaves_like" --type ruby
```

## Dependencies

```bash
# View Gemfile
cat Gemfile

# Find gem versions
rg "gem ['\"]" Gemfile

# Find all Gemfiles
fd "Gemfile$"
```
