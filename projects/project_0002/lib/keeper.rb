require_relative '../models/ukraine_run'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_intro'
require_relative '../../../concerns/game_modx/keeper'

class Keeper < Hamster::Keeper
  include GameModx::Keeper

  MADE_IN    = 'Ukraine'
  PARENT_PS5 = 21
  PARENT_PS4 = 22

  def delete_not_touched
    sg = SonyGame.joins(:sony_game_additional).active_games([PARENT_PS5, PARENT_PS4])
                 .where.not(sony_game_additional: { touched_run_id: run_id })
    sg.update(deleted: 1, deletedon: Time.current.to_i, deletedby: settings['user_id']) && @count[:deleted] += sg.size # TODO проверить update_all
  end

  def save_desc_lang(data, model)
    content = data.delete(:content)
    save_lang(data, model)
    save_content(content, model) if content && model.sony_game.content != content
  end

  def save_ua_games(games)
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
        SonyGame.store(game)
        @count[:saved] += 1
      end
    rescue ActiveRecord::RecordInvalid => e
      Hamster.logger.error "#{game[:main][:uri]} || #{e.message}"
    end
  end

  private

  def form_link(sony_id)
    settings['ps_game'].gsub('en-tr','ru-ua') + sony_id
  end

  def save_content(content, model)
    content.gsub!(/[Бб][Оо][Гг][Ии]?/, 'Human')
    data = { content: content, editedon: Time.current.to_i, editedby: settings['user_id'] }
    model.sony_game.update(data) && @count[:updated_desc] += 1
  end

  def form_description(title)
    <<~DESCR.squeeze(' ').chomp
      Вы искали игру #{title} PS Store Украина. Не знаете где купить? – Конечно же в PS-Ukraine.ru! 100% гарантия 
      от блокировок. Поддержка и консультация, акции и скидки.
    DESCR
  end
end
