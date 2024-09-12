require_relative '../models/turkish_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_intro'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'
require_relative '../../../concerns/game_modx/keeper'

class Keeper < Hamster::Keeper
  include GameModx::Keeper

  MADE_IN    = 'Turkish'
  PARENT_PS5 = Hamster.settings['parent_ps5']
  PARENT_PS4 = Hamster.settings['parent_ps4']

  def fetch_game_without_content
    games_ids = SonyGame.active_games([PARENT_PS5, PARENT_PS4]).where(content: [nil, '']).pluck(:id)
    search    = { id: games_ids }
    search[:run_id] = run_id if settings['touch_update_desc']
    SonyGameAdditional.where(search)
  end

  def save_desc_dd(data, game)
    @count[:updated_desc] ||= 0
    data.merge!({ editedon: Time.current.to_i, editedby: settings['user_id'] })
    game.update(data)
    @count[:updated_desc] += 1 if game.saved_changes?
  rescue ActiveRecord::StatementInvalid => e
    Hamster.logger.error "ID: #{id} | #{e.message}"
  end

  def save_games(games)
    game_additions = form_block_game_additions(games)
    games.each do |game|
      @count[:menu_id_count] += 1
      game_add       = game_additions.find { |i| i[:data_source_url] == game[:additional][:data_source_url] }
      image_link_raw = game[:additional].delete(:image_link_raw)
      form_start_game_data(game)

      if game_add.present?
        sony_game = game_add.sony_game
        check     = check_game(sony_game)
        update_date(game, game_add, sony_game) if check
      else
        form_new_game(game, image_link_raw)
        SonyGame.store(game)
        @count[:saved] += 1
      end
    end
  end

  private

  def form_link(sony_id)
    settings['ps_game'] + sony_id
  end

  def form_description(title)
    <<~DESCR.gsub(/\n/, '')
      Игра #{title}. Купить игру #{title[0..100]} сегодня по выгодной цене. Доставка - СПБ, Москва и вся Россия. 
      Вы искали игру #{title[0..100]} где купить? - Конечно же в Open-PS.ru! >> 100% гарантия от блокировок. 
      Поддержка и консультация, акции и скидки.
    DESCR
  end
end
