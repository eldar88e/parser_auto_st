require_relative './application_record'

class SonyGameRun < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_RUNS']
  #self.logger = Logger.new(STDOUT)
end
