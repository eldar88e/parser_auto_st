require_relative './application_record'

class PsUaRun < ApplicationRecord
  establish_connection(adapter: 'mysql2',
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('DATABASE_UA'),
                       username: ENV.fetch('USERNAME_UA'),
                       password: ENV.fetch('PASSWORD_UA'))
  self.table_name = 'ukraine_runs'
end
