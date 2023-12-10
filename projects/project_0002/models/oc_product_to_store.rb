require_relative './application_record_price'

class OcProductToStore < ApplicationRecordPrice
  self.table_name = 'oc_product_to_store'

  belongs_to :oc_product, foreign_key: 'product_id'
end
