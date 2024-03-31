class ApplicationRecord < ActiveRecord::Base
  establish_connection(adapter: 'mysql2',
                       host: ENV.fetch('HOST'),
                       database: ENV.fetch('DB_ECZANE'),
                       username: ENV.fetch('USER_ECZANE'),
                       password: ENV.fetch('PASS_ECZANE'))

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary
end
