require_relative './application_record_price'

class OcProduct < ApplicationRecordPrice
  self.table_name = 'oc_product'

  has_one :oc_product_description, foreign_key: 'product_id'
end
