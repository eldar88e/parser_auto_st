class Exporter < Hamster::Harvester
  HEAD = ["SKU",
          'Mark',
          "Название товара",
          "Цена",
          "Price Old",
          "Изображение",
          "Наличие русского языка в субтитрах",
          "Наличие русского языка в голосе",
          "Жанр игры",
          "Подробное описание",
          "Платформа",
          "Раздел",
          'SEO title',
          'SEO descr']
  MAIN_CATEGORY = 'Игры PlayStation'

  def initialize(keeper)
    super
    @keeper = keeper
  end

  def make_csv(domen)
    games_raw  = @keeper.list_last_popular_game(settings['limit_export'])
    games_list = convert_objects_list(games_raw, domen)
    CSV.generate { |csv| games_list.each { |row| csv << row } }
  end

  private

  def convert_objects_list(games_raw, domain)
    games = []
    games << HEAD
    games_raw.each do |game|
      item    = []
      item[0] = game.sony_game_additional.article
      item[1] = game.sony_game_additional.new ? 'Новинка' : ''
      item[2] = game.pagetitle
      item[3] = game.sony_game_additional.price.to_f.round
      item[4] = game.sony_game_additional.old_price&.to_f&.round
      sony_id = game.sony_game_additional.janr
      item[5] = "https://store.playstation.com/store/api/chihiro/00_09_000/container/TR/tr/99/#{sony_id}/0/image?w=600&h=600"
      item[6]  = game.sony_game_additional.rus_screen ? 'Да' : 'Нет'
      item[7]  = game.sony_game_additional.rus_voice ? 'Да' : 'Нет'
      item[8]  = game.sony_game_additional.genre
      item[9]  = game.content
      item[10] = game.sony_game_additional.platform
      item[11] = MAIN_CATEGORY
      seo      = Hamster::Seo.new(domain, game.pagetitle)
      item[12] = seo.title
      item[13] = seo.description

      games << item
    end
    games
  end
end
