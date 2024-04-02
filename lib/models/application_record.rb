class ApplicationRecord < ActiveRecord::Base

  self.abstract_class     = true
  self.inheritance_column = :_type_disabled
  include Hamster::Loggable
end
