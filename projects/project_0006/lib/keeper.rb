require_relative '../models/india_run'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_intro'
require_relative '../../../concerns/game_modx/keeper'

class Keeper < Hamster::Keeper
  include GameModx::Keeper

  MADE_IN    = 'India'
  PARENT_PS4 = 24
  PARENT_PS5 = 25

  def save_in_games(games)
    @ps4_path ||= make_parent_path(:ps4)
    @ps5_path ||= make_parent_path(:ps5)
    urls           = games.map { |i| i[:additional][:data_source_url] }
    game_additions = SonyGameAdditional.includes(:sony_game).where(data_source_url: urls)
    games.each do |game|
      @count[:menu_id_count] += 1
      game_add = game_additions.find { |i| i[:data_source_url] == game[:additional][:data_source_url] }
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus discount_end_date]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
      game[:additional][:popular]  = @count[:menu_id_count] < 151
      image_link_raw               = game[:additional].delete(:image_link_raw)

      if game_add.present?
        sony_game = game_add.sony_game
        check     = check_game(sony_game)
        update_date(game, game_add, sony_game) if check
      else
        form_new_game(game, image_link_raw)
        game[:content] = form_content(game[:additional][:janr])
        SonyGame.store(game)
        @count[:saved] += 1
      end
    rescue ActiveRecord::RecordInvalid => e
      Hamster.logger.error "#{game[:main][:uri]} || #{e.message}"
    end
  end

  private

  def form_link(sony_id)
    settings['ps_game'].gsub('en-tr','en-in') + sony_id
  end

  def form_content(sony_id)
    SonyGame.joins(:sony_game_additional)
            .where.not(content: ['', nil])
            .where(sony_game_additional: { janr: sony_id })
            .pluck(:content).first
  end

  def form_description(title)
    <<~DESCR.squeeze(' ').chomp
      Вы искали игру #{title} PS Store Индия. Не знаете где купить? – Конечно же в Open-PS! 100% гарантия 
      от блокировок. Поддержка и консультация, акции и скидки.
    DESCR
  end
end
