require_relative './application_record'

class ModxSiteTmplvarContentvalues < ApplicationRecord
  belongs_to :content, foreign_key: :contentid, class_name: 'ModxSiteContent'
end