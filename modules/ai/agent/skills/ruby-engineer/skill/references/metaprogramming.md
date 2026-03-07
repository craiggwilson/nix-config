# Ruby Metaprogramming

## Dynamic Methods

```ruby
class User
  ROLES = %w[admin moderator member]

  ROLES.each do |role|
    define_method("#{role}?") do
      self.role == role
    end
  end
end

user = User.new(role: 'admin')
user.admin?     # => true
user.moderator? # => false
```

## method_missing

```ruby
class FlexibleStruct
  def initialize(attributes = {})
    @attributes = attributes
  end

  def method_missing(name, *args)
    attribute = name.to_s.chomp('=')
    
    if name.to_s.end_with?('=')
      @attributes[attribute.to_sym] = args.first
    else
      @attributes[name]
    end
  end

  def respond_to_missing?(name, include_private = false)
    true
  end
end

struct = FlexibleStruct.new
struct.name = 'John'
struct.name # => 'John'
```

## Class Macros

```ruby
module Validatable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validates_presence_of(*attributes)
      attributes.each do |attr|
        define_method("#{attr}_valid?") do
          !send(attr).nil? && !send(attr).empty?
        end
      end
    end
  end
end

class User
  include Validatable
  attr_accessor :name, :email
  
  validates_presence_of :name, :email
end
```

## DSL Building

```ruby
class Router
  def initialize(&block)
    @routes = []
    instance_eval(&block) if block_given?
  end

  def get(path, to:)
    @routes << { method: :get, path: path, handler: to }
  end

  def post(path, to:)
    @routes << { method: :post, path: path, handler: to }
  end
end

router = Router.new do
  get '/users', to: 'users#index'
  post '/users', to: 'users#create'
end
```

## Hooks

```ruby
module Callbacks
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def before_save(*methods)
      @before_save_callbacks ||= []
      @before_save_callbacks.concat(methods)
    end

    def before_save_callbacks
      @before_save_callbacks || []
    end
  end

  def save
    self.class.before_save_callbacks.each { |m| send(m) }
    # actual save logic
  end
end
```

## Safety Tips

- Always implement `respond_to_missing?` with `method_missing`
- Document metaprogramming heavily
- Prefer explicit over implicit
- Test thoroughly
- Consider performance implications
