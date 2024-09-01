require_relative './application_record'
require_relative './vendor'
class Content < ApplicationRecord
  validates :alias, uniqueness: true

  ########
  self.table_name = 'modx_site_content'
  #########

  has_one :product, foreign_key: 'id'   #optional: true
  has_one :intro, foreign_key: 'resource'

  #has_many :sony_game_category, foreign_key: 'product_id', optional: true

  scope :active_contents, ->(parent) { where(deleted: 0, published: 1, parent: parent) }

  def self.store(data)
    self.transaction do
      content = Content.find_by(alias: data[:main][:alias]) || self.create!(data[:main])
      data.delete(:main)
      intro  = data.delete(:intro)
      content.build_product(data).save
      content.build_intro(intro).save
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end

  private

  def self.save_vendor(vendor, data)
    return unless vendor

    vendor_db = Vendor.find_by(name: vendor)
    if vendor_db.nil?
        content_vendor = make_content_vendor(vendor)
        vendor_db = Vendor.create!(name: vendor, resource: content_vendor.id)
    end

    data.merge!(vendor: vendor_db.id)
  end

  def self.make_content_vendor(vendor)
    content_vendor_db = Content.find_by(pagetitle: vendor)
    return content_vendor_db if content_vendor_db

    data               = {}
    crnt_time          = Time.current.to_i
    data[:template]    = 16
    data[:properties]  = '{"stercseo":{"index":"1","follow":"1","sitemap":"1","priority":"0.5","changefreq":"weekly"}}'
    data[:publishedon] = crnt_time
    data[:publishedby] = 3
    data[:createdon]   = crnt_time
    data[:createdby]   = data[:publishedby]
    data[:parent]      = 77
    data[:published]   = 1
    data[:pagetitle]   = vendor
    data[:description] = data[:pagetitle]
    data[:uri]         = vendor.gsub("İ", 'i').downcase.gsub(/[ _]/, '-').gsub('ç', 'c')
    data[:alias]       = data[:uri]
    data[:class_key]   = 'modDocument'
    data[:description] = data[:pagetitle]
    Content.create!(data)
  end
end
