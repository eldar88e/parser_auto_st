require_relative './application_record'

class Intro < ApplicationRecord
  self.table_name = 'modx_mse2_intro'

  belongs_to :content
end
