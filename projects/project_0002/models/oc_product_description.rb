require_relative './application_record_price'

class OcProductDescription < ApplicationRecordPrice
  self.table_name = 'oc_product_description'

  belongs_to :oc_product, foreign_key: 'product_id'
end
