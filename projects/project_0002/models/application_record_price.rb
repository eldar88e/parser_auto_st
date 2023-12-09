class ApplicationRecordPrice < ActiveRecord::Base
  establish_connection(adapter: ENV.fetch('ADAPTER') { 'mysql2' },
                       host: ENV.fetch('HOST') { 'localhost' },
                       database: 'eldarap0_psprice',
                       username: 'eldarap0_psprice',
                       password: 'Eldar2023')

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary
end
