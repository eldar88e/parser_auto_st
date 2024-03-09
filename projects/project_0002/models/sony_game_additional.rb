require_relative './application_record'

class SonyGameAdditional < ApplicationRecord

  belongs_to :sony_game, foreign_key: id
end
