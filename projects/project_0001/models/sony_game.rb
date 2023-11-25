require_relative './application_record'

class SonyGame < ApplicationRecord
  SMALL_SIZE      = '50&h=50'
  MIDDLE_SIZE     = '320&h=320'
  self.table_name = ENV['BD_TABLE_NAME_MAIN']

  def self.store(data)
    self.transaction do
      sony_game_id = self.create!(data[:main]).id
      additional   = data[:additional]
      additional.merge!(id: sony_game_id)
      SonyGameAdditional.create!(additional)
      SonyGameCategories.store(product_id: sony_game_id, category_id: data[:main][:parent])
      file   = data[:file].merge!(product_id: sony_game_id)
      parent = 0
      paths  = %w[/ /100x98/ /520x508/]
      paths.each_with_index do |item, idx|
        new_file = {}
        new_file.merge!(file).merge!(path: "#{sony_game_id}#{item}", parent: parent)
        if item == paths[1]
          new_file[:url] = file[:url].sub(/720&h=720/, SMALL_SIZE)
        elsif item == paths[2]
          new_file[:url] = file[:url].sub(/720&h=720/, MIDDLE_SIZE)
        end
        file_db = SonyGameAdditionalFile.create!(new_file)
        parent = file_db.id if idx.zero?
      end

      nil
    end
  rescue ActiveRecord::RecordNotUnique
    # To prevent not unique error
  end
end
