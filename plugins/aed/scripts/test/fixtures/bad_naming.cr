# AED linter fixture — Crystal naming the canon would push back on.
# Every rule that applies to Crystal fires somewhere in this file.
class Customers < Granite::Base
  property name : String
  property data : String
  property locked : Bool = false
  property orders : Array(Order) = [] of Order
  property lookup : Hash(String, Order) = {} of String => Order
  property x : Int32 = 0

  def initialize(@name, @data)
  end
end

class LockCustomers
  property customer_to_lock : Customer

  def initialize(@customer_to_lock)
  end

  def perform
    tmp = @customer_to_lock
    [tmp].each { |c| puts c }
  end
end

class DoTheAccountLocking
  property customer_to_lock : Customer

  def initialize(@customer_to_lock)
  end

  def perform(customer)
    customer
  end
end
