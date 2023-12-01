require_relative '../models/application_record'

class Setting < ApplicationRecord
  self.table_name = ENV['BD_TABLE_NAME_SETTING']
  #ActiveRecord::Base.logger = Logger.new($stdout)
end
