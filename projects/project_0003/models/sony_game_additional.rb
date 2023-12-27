require_relative './application_record'

class SonyGameAdditional < ApplicationRecord
  validates :md5_hash, uniqueness: true

  self.table_name = ENV['BD_TABLE_NAME_ADDITIONAL']

  belongs_to :sony_game
end
