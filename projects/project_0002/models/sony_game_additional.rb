require_relative './application_record'

class SonyGameAdditional < ApplicationRecord
  validates :data_source_url, uniqueness: true
  validates :janr, uniqueness: true
  validates :md5_hash, uniqueness: true

  self.table_name = ENV['BD_TABLE_NAME_ADDITIONAL']

  belongs_to :sony_game, foreign_key: 'id'
end
