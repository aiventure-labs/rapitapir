# frozen_string_literal: true

class CreateIdeas < ActiveRecord::Migration[7.1]
  def change
    create_table :ideas do |t|
      t.string :name
      t.timestamps
    end
  end
end
