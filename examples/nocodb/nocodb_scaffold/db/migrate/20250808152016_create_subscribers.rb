# frozen_string_literal: true

class CreateSubscribers < ActiveRecord::Migration[7.1]
  def change
    create_table :subscribers do |t|
      t.string :name
      t.timestamps
    end
  end
end
