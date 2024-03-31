require_relative './application_record'

class SonyGameCategories < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_CATEGORIES']

  #belongs_to :sony_game
end
