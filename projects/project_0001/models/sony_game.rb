require_relative './application_record'

class SonyGame < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_MAIN']

  validates :uri, uniqueness: true

  has_one :sony_game_additional, foreign_key: 'id'   #optional: true
  has_one :sony_game_intro, foreign_key: 'resource'
  #has_many :sony_game_category, foreign_key: 'product_id', optional: true

  scope :active_games, -> (parent) { where(deleted: 0, published: 1, parent: parent) }

  def self.store(data)
    self.transaction do
      sony_game_id    = self.create!(data[:main]).id
      additional      = data[:additional]
      additional[:id] = sony_game_id
      SonyGameAdditional.create!(additional)
      SonyGameCategories.store(data[:category].merge(product_id: sony_game_id)) if data[:category]
      SonyGameIntro.store(data[:intro].merge(resource: sony_game_id))
      sony_game_id
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end
end
