require_relative './application_record'

class SonyGame < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_MAIN']

  def self.store(data)
    self.transaction do
      sony_game_id = self.create!(data[:main]).id
      additional   = data[:additional]
      additional.merge!(id: sony_game_id)
      SonyGameAdditional.create!(additional)
      SonyGameCategories.store(product_id: sony_game_id, category_id: data[:main][:parent])
      sony_game_id
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end
end
