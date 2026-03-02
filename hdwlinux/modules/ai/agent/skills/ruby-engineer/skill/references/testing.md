# Ruby Testing

## RSpec Basics

```ruby
RSpec.describe User do
  describe '#full_name' do
    it 'returns first and last name' do
      user = User.new(first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:orders) }
    it { is_expected.to belong_to(:organization) }
  end
end
```

## FactoryBot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { 'John Doe' }
    password { 'password123' }

    trait :admin do
      role { :admin }
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end

# Usage
user = create(:user)
admin = create(:user, :admin)
user_with_orders = create(:user, :with_orders)
```

## Mocking

```ruby
RSpec.describe OrderService do
  describe '#process' do
    let(:payment_gateway) { instance_double(PaymentGateway) }
    let(:service) { described_class.new(payment_gateway: payment_gateway) }

    it 'charges the payment' do
      allow(payment_gateway).to receive(:charge).and_return(true)
      
      service.process(order)
      
      expect(payment_gateway).to have_received(:charge).with(order.total)
    end
  end
end
```

## Request Specs

```ruby
RSpec.describe 'Users API', type: :request do
  describe 'GET /users/:id' do
    let(:user) { create(:user) }

    it 'returns the user' do
      get "/users/#{user.id}"

      expect(response).to have_http_status(:ok)
      expect(json_response['email']).to eq(user.email)
    end
  end

  describe 'POST /users' do
    let(:valid_params) { { user: { email: 'new@example.com', name: 'New' } } }

    it 'creates a user' do
      expect {
        post '/users', params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
```

## Shared Examples

```ruby
RSpec.shared_examples 'a paginated endpoint' do
  it 'returns pagination metadata' do
    expect(json_response).to include('page', 'per_page', 'total')
  end
end

RSpec.describe 'Users API' do
  describe 'GET /users' do
    before { get '/users' }
    it_behaves_like 'a paginated endpoint'
  end
end
```
