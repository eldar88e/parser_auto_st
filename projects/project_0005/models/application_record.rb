class ApplicationRecord < ActiveRecord::Base
  establish_connection(adapter: 'mysql2',
                       host: 'eldarap0.beget.tech',
                       database: 'eldarap0_eczanes',
                       username: 'eldarap0_eczanes',
                       password: 'ZE%Jq2%f')

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
  include Hamster::Granary
end
