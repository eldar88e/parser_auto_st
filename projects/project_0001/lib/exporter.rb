class Exporter < Hamster::Harvester
  HEAD = ["SKU - артикул",
          "Название товара",
          "Цена",
          "Старая цена",
          "Изображение",
          "Наличие русского языка в субтитрах",
          "Наличие русского языка в голосе",
          "Жанр игры",
          "Подробное описание",
          "Платформа",
          "Раздел"]

  def initialize(keeper)
    super
    @keeper = keeper
  end

  def make_csv
    games_raw  = @keeper.list_last_popular_game(settings['limit_export'], [settings['parent_ps5'], settings['parent_ps4']])
    games_list = convert_objects_list(games_raw)
    csv_string = CSV.generate { |csv| games_list.each { |row| csv << row } }

    peon.put(file: "#{@keeper.run_id}_games.csv", content: csv_string)
  end

  private

  def convert_objects_list(games_raw)
    games = []
    games << HEAD
    games_raw.each do |game|
      item    = []
      item[0] = game.sony_game_additional.article
      item[1] = game.pagetitle
      item[2] = game.sony_game_additional.price.to_f.round
      item[3] = game.sony_game_additional.old_price&.to_f&.round
      sony_id = game.sony_game_additional.janr
      item[4] = "https://store.playstation.com/store/api/chihiro/00_09_000/container/TR/tr/99/"\
        "#{sony_id}/0/image?_version=00_09_000&platform=chihiro&bg_color=000000&opacity=100&w=586&h=586"
      item[5]  = game.sony_game_additional.rus_screen ? 'Да' : 'Нет'
      item[6]  = game.sony_game_additional.rus_voice ? 'Да' : 'Нет'
      item[7]  = game.sony_game_additional.genre
      item[8]  = game.content
      item[9]  = game.sony_game_additional.platform
      item[10] = 'Игры PlayStation'

      games << item
    end
    games
  end
end
