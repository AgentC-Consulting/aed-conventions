module GoodFrameworkProcessOverrides
  class OrdersController < ApplicationController
    def process(input_value); end
  end
  class ProcessReceipt
  end
end
