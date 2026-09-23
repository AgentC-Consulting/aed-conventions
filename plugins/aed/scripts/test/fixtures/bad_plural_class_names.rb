module BadPluralClassNames
  class Orders
    attr_accessor :order_id
  end

  class CustomerAddresses
    attr_accessor :customer_address_id
  end

  class Analyses
    include JSON::Serializable
  end
end
