module GameModx
  module Exporter
    SLICE_LIMIT = 500
    PARAMS      = {
      'Турция' => { id: 2, id_bonus: 5, id_old: 8,  id_date: 9 },
      'Украина' => { id: 3, id_bonus: 6, id_old: 10, id_date: 11 },
      'Индия' => { id: 4, id_bonus: 7, id_old: 12, id_date: 13 }
    }.freeze

    def update_google_sheets
      games_raw   = @keeper.list_last_popular_game(nil)
      spreadsheet = GoogleDrive::Session.from_service_account_key('key.open-parser.json')
                                        .file_by_id('1-0kt35pFciXYD8_U8Qag50gHwxUAF_A_mtCBd17IL78')
      worksheet   = spreadsheet.worksheets.first # list = fetch_list   # send(list)
      count       = [0, 0]
      games_raw.each_slice(SLICE_LIMIT) do |sliced_games|
        sliced_games.each do |row|
          additional = row.sony_game_additional
          game       = worksheet.rows.find { |i| i[14] == additional.janr || i[0] == "#{row.pagetitle} [#{additional.platform}]" }
            #worksheet.rows.find { |i| i[0] == "#{row.pagetitle} [#{additional.platform}]" }
          idx        = form_row_id(worksheet, game, count)
          worksheet.update_cells(idx, 1, [form_row(row)])
        rescue => e
          puts e.message.colorize(:red)
          binding.pry
        end
        worksheet.save
      end
      "✅ Updated #{count[0]} and created #{count[1]} games for Google Sheets."
    end

    private

    def form_row_id(worksheet, game, count)
      if game
        count[0] += 1
        worksheet.rows.index(game) + 1
      else
        total_rows = worksheet.num_rows
        count[1] += 1
        total_rows + 1
      end
    end

    def form_row(row)
      id, id_bonus, id_old, id_date = make_id
      data = []
      additional = row.sony_game_additional
      data << "#{row.pagetitle} [#{additional.platform}]"
      data[id]          = "#{additional.price.to_i}₽"
      discount_end_date = additional.discount_end_date
      data[id_old-1]    = discount_end_date ? "#{additional.old_price.to_i}₽" : nil
      data[id_date-1]   = discount_end_date || ''
      data[id_bonus-1]  = additional.price_bonus ? "#{additional.price_bonus.to_i}₽" : nil
      data[13]          = additional.janr
      data
    end

    def fetch_list
      case @keeper.class::MADE_IN
      when 'Турция'
        :first
      when 'Украина'
        :second
      else
        :third
      end
    end

    def make_id
      %i[id id_bonus id_old id_date].map { |id| PARAMS[@keeper.class::MADE_IN][id] }
    end

    def make_url(additional)
      url = "https://store.playstation.com/en-tr/product/#{additional.janr}"
      return url if additional.made_in == "Турция"

      additional.made_in == "Украина" ? url.gsub!('en-tr', 'ua-ru') : url.gsub!('en-tr', 'en-in')
      url
    end
  end
end
