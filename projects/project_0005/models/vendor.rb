require_relative './application_record'

class Vendor < ApplicationRecord
  self.table_name = 'modx_ms2_vendors'
end