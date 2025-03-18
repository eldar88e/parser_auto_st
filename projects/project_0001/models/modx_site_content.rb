require_relative './application_record'

class ModxSiteContent < ApplicationRecord
  self.table_name = 'modx_site_content'

  has_many :tv, foreign_key: :contentid, class_name: 'ModxSiteTmplvarContentvalues'
  has_many :children, foreign_key: :parent, class_name: 'ModxSiteContent'
  belongs_to :parent_attr, foreign_key: :parent, class_name: 'ModxSiteContent', optional: true

  validates :uri, uniqueness: true

  # scope :active, -> (parent) { where(deleted: 0, published: 1, parent: parent) }
end
