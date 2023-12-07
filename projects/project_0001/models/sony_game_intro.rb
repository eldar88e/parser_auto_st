require_relative './application_record'

class SonyGameIntro < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_INTRO']

  belongs_to :sony_game
end
