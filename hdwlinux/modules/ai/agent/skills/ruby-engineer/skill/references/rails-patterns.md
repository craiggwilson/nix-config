# Rails Patterns

## Service Objects

```ruby
# app/services/users/create_service.rb
module Users
  class CreateService
    def initialize(params:, current_user: nil)
      @params = params
      @current_user = current_user
    end

    def call
      user = User.new(permitted_params)
      
      ActiveRecord::Base.transaction do
        user.save!
        send_welcome_email(user)
        track_signup(user)
      end

      Result.success(user)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors)
    end

    private

    attr_reader :params, :current_user

    def permitted_params
      params.slice(:name, :email, :password)
    end
  end
end

# Usage
result = Users::CreateService.new(params: user_params).call
if result.success?
  render json: result.value
else
  render json: { errors: result.errors }, status: :unprocessable_entity
end
```

## Query Objects

```ruby
# app/queries/users/active_query.rb
module Users
  class ActiveQuery
    def initialize(relation = User.all)
      @relation = relation
    end

    def call(since: 30.days.ago)
      @relation
        .where(status: :active)
        .where('last_login_at > ?', since)
        .order(last_login_at: :desc)
    end
  end
end

# Usage
Users::ActiveQuery.new.call(since: 7.days.ago)
```

## Form Objects

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :name, :email, :password, :terms_accepted

  validates :name, :email, :password, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?

    User.create!(name: name, email: email, password: password)
  end
end
```

## Concerns

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(query) {
      where('name ILIKE ?', "%#{query}%")
    }
  end

  class_methods do
    def search_fields
      [:name]
    end
  end
end

# Usage in model
class User < ApplicationRecord
  include Searchable
end
```

## Presenters/Decorators

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < SimpleDelegator
  def display_name
    "#{first_name} #{last_name}".strip.presence || email
  end

  def avatar_url
    gravatar_url || default_avatar_url
  end

  private

  def gravatar_url
    hash = Digest::MD5.hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{hash}"
  end
end
```
