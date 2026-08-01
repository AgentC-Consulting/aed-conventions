# AED linter fixture — Ruby naming the canon would push back on.
# Every rule that applies to Ruby fires somewhere in this file.
module BadFixture
  class Orders < ApplicationRecord
    attr_accessor :name, :status
    attr_writer :data

    attribute :locked, :boolean
  end
end

class AddLockedFlagToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :locked, :boolean
    create_table :order_locks do |t|
      t.boolean :active
    end
  end
end

class LockOrders
  def initialize(order)
    @o = order
  end

  def perform
    res = @o
    [res].each { |o| puts o }
  end
end

class DoTheOrderLocking
  def initialize(order_to_lock)
    @order_to_lock = order_to_lock
  end

  def perform(order_to_lock)
    order_to_lock
  end
end
