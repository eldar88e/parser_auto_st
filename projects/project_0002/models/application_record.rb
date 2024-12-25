class ApplicationRecord < ActiveRecord::Base
  establish_connection(adapter: 'mysql2',
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('DATABASE_UA'),
                       username: ENV.fetch('USERNAME_UA'),
                       password: ENV.fetch('PASSWORD_UA'))

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  self.logger = Logger.new(STDOUT) if ENV.fetch('DEBUG', false)
  include Hamster::Granary
end
