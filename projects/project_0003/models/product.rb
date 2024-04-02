require_relative './application_record'

class Product < ApplicationRecord
  establish_connection(adapter: ENV.fetch('ADAPTER') { 'mysql2' },
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('DATABASE_UA'),
                       username: ENV.fetch('DATABASE_UA'),
                       password: ENV.fetch('PASSWORD_UA'))

  self.table_name = 'modx_ms2_products'

  belongs_to :content, foreign_key: 'id'
end
