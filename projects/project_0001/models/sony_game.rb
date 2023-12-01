require_relative './application_record'

class SonyGame < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_MAIN']

  scope :active_games, ->(parent) { where(deleted: 0, published: 1, parent: parent) }

  def self.store(data)
    self.transaction do
      sony_game_id    = self.create!(data[:main]).id
      additional      = data[:additional]
      additional[:id] = sony_game_id
      SonyGameAdditional.create!(additional)
      SonyGameCategories.store(data[:category].merge(product_id: sony_game_id)) if data[:category]
      SonyGameIntro.store(data[:intro])
      sony_game_id
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end
end
