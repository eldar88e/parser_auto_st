class ApplicationRecordPrice < ActiveRecord::Base
  establish_connection(adapter: ENV.fetch('ADAPTER') { 'mysql2' },
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: ENV.fetch('OC_DATABASE'),
                       username: ENV.fetch('OC_USERNAME'),
                       password: ENV.fetch('OC_PASSWORD'))

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary
end
