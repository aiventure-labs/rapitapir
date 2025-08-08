# frozen_string_literal: true

class CreateItineraryDays < ActiveRecord::Migration[7.1]
  def change
    create_table :itinerary_days do |t|
      t.string :name
      t.timestamps
    end
  end
end
