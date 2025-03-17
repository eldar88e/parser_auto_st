require_relative './application_record'

class ModxSiteContent < ApplicationRecord
  self.table_name = 'modx_site_content'

  has_many :tv, foreign_key: :contentid, class_name: 'ModxSiteTmplvarContentvalues'

  validates :uri, uniqueness: true

  # scope :active, -> (parent) { where(deleted: 0, published: 1, parent: parent) }

  def self.store(data)
    self.transaction do
      sony_game_id    = self.create!(data[:main]).id
      sony_game_id
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end
end
