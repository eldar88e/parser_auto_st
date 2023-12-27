require_relative './application_record'

class SonyGameAdditionalFile < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_ADDITIONAL_FILES']
end
