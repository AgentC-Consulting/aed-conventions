# AED linter fixture — Ruby naming the canon would accept.
# Modelled on the canon's own Rails process manager example.
# Expectation: zero findings of any severity.
module GoodNaming
  class Customer < ApplicationRecord
    attr_reader :first_name, :last_name, :email_address

    attribute :has_a_valid_payment_method, :boolean
    attribute :is_this_an_enterprise_customer, :boolean
  end

  class UpdateCustomerPaymentAndSubscription
    attr_reader :customer_to_update, :new_payment_method_to_apply

    def initialize(customer_to_update:, new_payment_method_to_apply:)
      @customer_to_update = customer_to_update
      @new_payment_method_to_apply = new_payment_method_to_apply
    end

    def perform
      update_the_customers_payment_method && update_the_customers_subscription_status
    end

    private def update_the_customers_payment_method
      customer_to_update.update(payment_method: new_payment_method_to_apply)
    end

    private def update_the_customers_subscription_status
      list_of_subscriptions_to_reactivate = customer_to_update.subscriptions.select do |subscription_record|
        subscription_record.currently_expired?
      end
      list_of_subscriptions_to_reactivate.each { |subscription_record| subscription_record.reactivate! }
    end

    private def keep_worker_reference_alive(worker_task)
      _ = worker_task
      _ignored_result = worker_task
    end
  end
end
