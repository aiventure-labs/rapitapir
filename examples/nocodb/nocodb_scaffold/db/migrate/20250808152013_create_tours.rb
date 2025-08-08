# frozen_string_literal: true

class CreateTours < ActiveRecord::Migration[7.1]
  def change
    create_table :tours do |t|
      t.string :name
      t.timestamps
    end
  end
end
