# AED linter fixture — Crystal naming the canon would accept.
# Modelled on the canon's own example (quick_reference.md).
# Expectation: zero findings of any severity.
module GoodNaming
  class Customer < Granite::Base
    property first_name : String
    property last_name : String
    property email_address : String
    property list_of_all_active_subscriptions : Array(Subscription) = [] of Subscription
    property is_this_an_enterprise_customer : Bool = false
    property subscription_totals_by_billing_period : Hash(String, Int32) = {} of String => Int32

    def initialize(@first_name, @last_name, @email_address, @is_this_an_enterprise_customer = false)
    end
  end

  class ProcessCustomersWithExpiredPaymentMethods
    property collection_of_customers_that_have_expired_payment_methods : Array(Customer) = [] of Customer
    property collection_of_customers_that_were_retried_and_failed : Array(Customer) = [] of Customer
    property all_of_the_customers_have_been_processed : Bool = false

    def initialize(@collection_of_customers_that_have_expired_payment_methods)
    end

    def perform
      retry_customers_who_failed_payment_processing_with_an_expired_card
      mark_customer_accounts_as_delinquent_and_prevent_further_use
      @all_of_the_customers_have_been_processed = true
    end

    private def retry_customers_who_failed_payment_processing_with_an_expired_card
      collection_of_customers_that_have_expired_payment_methods.each do |customer_with_an_expired_payment_method|
        customer_that_failed_the_retry = attempt_one_payment_retry_for(customer_with_an_expired_payment_method)
        collection_of_customers_that_were_retried_and_failed << customer_that_failed_the_retry
      end
    end

    private def attempt_one_payment_retry_for(customer_with_an_expired_payment_method : Customer)
      customer_with_an_expired_payment_method
    end

    private def keep_worker_reference_alive(worker_task : Task)
      _ = worker_task
      _ignored_result = worker_task
    end

    private def mark_customer_accounts_as_delinquent_and_prevent_further_use
      # Your business logic goes here
    end
  end
end
