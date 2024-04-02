require_relative './application_record'
class Content < ApplicationRecord
  establish_connection(adapter: ENV.fetch('ADAPTER') { 'mysql2' },
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('DATABASE_UA'),
                       username: ENV.fetch('DATABASE_UA'),
                       password: ENV.fetch('PASSWORD_UA'))

  self.table_name = 'modx_site_content'

  has_one :product, foreign_key: 'id'   #optional: true

  #has_many :sony_game_category, foreign_key: 'product_id', optional: true

  scope :active_contents, ->(parent) { where(deleted: 0, published: 1, parent: parent) }
end
