require_relative './application_record_price'

class OcProduct < ApplicationRecordPrice
  self.table_name = 'oc_product'

  has_one :oc_product_description, foreign_key: 'product_id'
  has_many :oc_product_to_category, foreign_key: 'product_id'
  has_one :oc_product_to_store, foreign_key: 'product_id'
  has_one :oc_product_to_layout, foreign_key: 'product_id'
end
