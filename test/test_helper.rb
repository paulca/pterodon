ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Minimal Object#stub for tests (minitest 6.0 extracted minitest/mock)
class Object
  def stub(name, val_or_callable, *block_args, &block)
    new_name = "__stub__#{name}"

    metaclass = class << self; self; end
    metaclass.alias_method new_name, name

    if val_or_callable.respond_to?(:call)
      metaclass.define_method(name) { |*args, **kwargs| val_or_callable.call(*args, **kwargs) }
    else
      metaclass.define_method(name) { |*args, **kwargs| val_or_callable }
    end

    yield self
  ensure
    metaclass.undef_method name
    metaclass.alias_method name, new_name
    metaclass.undef_method new_name
  end
end

module SignInHelper
  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
