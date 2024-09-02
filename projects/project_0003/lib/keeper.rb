require_relative '../models/ukraine_run'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_intro'
require_relative '../models/content'
require_relative '../models/product'
require_relative '../../../concerns/game_modx/keeper'

class Keeper < Hamster::Keeper
  include GameModx::Keeper

  MADE_IN    = 'Ukraine'
  PARENT_PS5 = 21
  PARENT_PS4 = 22

  def import_top_games
    product_keys = %i[pagetitle alias content article price old_price image thumb price_tl old_price_tl site_link
                      janr data_source_url platform price_bonus price_bonus_tl type_game rus_voice rus_screen
                      genre release publisher discount_end_date]
    games_row    = get_top_games(product_keys)
    content_key  = %i[pagetitle alias content]
    product_keys -= content_key
    games_row.each do |game|
      save_ua_games({ main: content_key.zip(game[0..(content_key.size - 1)]).to_h,
                      additional: product_keys.zip(game[content_key.size..-1]).to_h })
    rescue ActiveRecord::RecordInvalid => e
      Hamster.logger.error "#{game[12]} || #{e.message}"
    end
  end

  private

  def get_top_games(game_key)
    Content.order(:menuindex).active_contents([PARENT_PS5, PARENT_PS4])
           .includes(:product).limit(@quantity).pluck(*game_key)
  end

  def save_ua_games(game)
    @count[:menu_id_count] += 1
    game_add       = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url])
    image_link_raw = game[:additional][:image].sub(settings['medium_size'], '720&h=720')
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

  def form_link(sony_id)
    settings['ps_game'].gsub('en-tr','ru-ua') + sony_id
  end

  def form_description(title)
    <<~DESCR
      Вы искали игру #{title} PS Store Украина. Не знаете где купить? - Конечно же в Open-PS.ru! >> 100% гарантия 
      от блокировок. Поддержка и консультация, акции и скидки.
    DESCR
  end
end
