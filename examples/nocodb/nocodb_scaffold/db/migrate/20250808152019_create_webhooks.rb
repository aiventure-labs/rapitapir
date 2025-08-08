# frozen_string_literal: true

class CreateWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :webhooks do |t|
      t.string :name
      t.timestamps
    end
  end
end
