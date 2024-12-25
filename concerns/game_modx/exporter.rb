module GameModx
  module Exporter
    SLICE_LIMIT = 500
    PARAMS      = {
      'Турция'  => { price: 1, price_plus: 4, price_old: 7, date: 10 },
      'Украина' => { price: 2, price_plus: 5, price_old: 8, date: 11 },
      'Индия'   => { price: 3, price_plus: 6, price_old: 9, date: 12 }
    }.freeze
    FIRST_COLUMN = [
      'Название игры', 'Цена Турция', 'Цена Украина', 'Цена Индия',
      'Цена с PS Plus Турция', 'Цена с PS Plus Украина', 'Цена с PS Plus Индия',
      'Цена старая Турция', 'Цена старая Украина', 'Цена старая Индия',
      'Дата скидки Турция', 'Дата скидки Украина', 'Дата скидки Индия', ''
    ].freeze

    def update_google_sheets
      games_raw      = @keeper.list_last_popular_game(nil)
      spreadsheet    = GoogleDrive::Session.from_service_account_key('key.open-parser.json')
                                           .file_by_id('1-0kt35pFciXYD8_U8Qag50gHwxUAF_A_mtCBd17IL78')
      worksheet      = spreadsheet.worksheets.first

      write_first_column(worksheet)

      sony_id_index  = worksheet.rows[1..].each_with_index.to_h { |row, idx| [row[13], idx + 2] }
      # title_index    = worksheet.rows[1..].each_with_index.to_h { |row, idx| [row[0], idx + 2] }
      worksheet_size = worksheet.rows.size
      count          = [0, 0]
      updates        = []

      games_raw.each_slice(SLICE_LIMIT) do |sliced_games|
        sliced_games.each do |game|
          additional  = game.sony_game_additional
          game_row_id = max_row(game, worksheet_size, sony_id_index) #, title_index)
          data        = form_row(game)

          updates << { row: game_row_id, data: data }

          if sony_id_index[additional.janr] # || title_index["#{game.pagetitle} [#{additional.platform}]"]
            count[0] += 1
          else
            count[1] += 1
            sony_id_index[additional.janr] = game_row_id
          end
        end
      end

      apply_updates(worksheet, updates)
      worksheet.save

      count
    end

    private

    def write_first_column(worksheet)
      first_row = worksheet.rows[0]
      return if first_row == FIRST_COLUMN

      worksheet.update_cells(1, 1, [FIRST_COLUMN])
      worksheet.save
    end

    def max_row(game, worksheet_size, sony_id_index) #, title_index)
      additional = game.sony_game_additional
      sony_id_index[additional.janr] || # title_index["#{game.pagetitle} [#{additional.platform}]"] ||
      [worksheet_size + 1, (sony_id_index.values.max || 1) + 1].max # , (title_index.values.max || 1) + 1
    end

    def apply_updates(worksheet, updates)
      updates.each { |update| update[:data].each { |key, val| worksheet[update[:row], key + 1] = val } }
    end

    def form_row(row)
      id, id_bonus, id_old, id_date = make_id
      additional     = row.sony_game_additional
      data           = {}
      data[0]        = "#{row.pagetitle} [#{additional.platform}]"
      data[id]       = "#{additional.price.to_i}₽"
      data[id_bonus] = "#{additional.price_bonus.to_i}₽" if additional.price_bonus.present?
      data[id_old]   = "#{additional.old_price.to_i}₽" if additional.old_price.present?
      data[id_date]  = additional.discount_end_date if additional.old_price.present? && additional.discount_end_date.present?
      data[13]       = additional.janr  # sony_id
      data
    end

    def make_id
      %i[price price_plus price_old date].map { |key| PARAMS[@keeper.class::MADE_IN][key] }
    end
  end
end
