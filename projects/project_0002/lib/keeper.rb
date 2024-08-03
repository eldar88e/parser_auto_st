require_relative '../models/run'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_intro'

class Keeper < Hamster::Keeper
  SOURCE     = 3
  PARENT_PS5 = 21
  PARENT_PS4 = 22
  MADE_IN    = 'Ukraine'

  def initialize(settings)
    super
    @settings = settings
    @run_id   = run.run_id
    @count    = { count: 0, menu_id_count: 0, saved: 0, updated: 0, updated_menu_id: 0,
                  skipped: 0, deleted: 0, updated_lang: 0, updated_desc: 0, restored: 0 }
  end

  attr_reader :run_id, :count

  def status=(new_status)
    run.status = new_status
  end

  def status
    run.status
  end

  def finish
    run.finish
  end

  def delete_not_touched
    sg = SonyGame.includes(:sony_game_additional).active_games([PARENT_PS5, PARENT_PS4])
                 .where.not(sony_game_additional: { touched_run_id: run_id })
    sg.update(deleted: 1, deletedon: Time.current.to_i, deletedby: settings['user_id']) && @count[:deleted] += sg.size
  end

  def get_game_without_desc
    result = SonyGame.active_games([PARENT_PS5, PARENT_PS4]).where(content: [nil, '']).includes(:sony_game_additional)
    @settings[:touch_update_desc] ? result.where(sony_game_additional: { run_id: run_id }) : result
  end

  def save_desc_lang(data, model)
    content = data.delete(:content)
    model.sony_game_additional.update(data) && @count[:updated_lang] += 1 if data[:rus_voice] && data[:rus_voice] != 0

    if content
      content.gsub!(/[Бб][Оо][Гг][Ии]?/, 'Human')
      data = { content: content, editedon: Time.current.to_i, editedby: settings['user_id'] }
      model.update(data) && @count[:updated_desc] += 1 if model.content != content
    end
  rescue ActiveRecord::StatementInvalid => e
    Hamster.logger.error "ID: #{model.id} | #{e.message}"
  end

  def get_all_game_without_rus
    SonyGame.active_games([PARENT_PS5, PARENT_PS4]).includes(:sony_game_additional)
            .where(sony_game_additional: { rus_voice: 0 }).limit(settings['limit_upd_lang'])
  end

  def save_ua_games(games)
    @ps4_path ||= make_parent_path(:ps4)
    @ps5_path ||= make_parent_path(:ps5)
    games.each do |game|
      @count[:menu_id_count] += 1
      game_add = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url])
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus discount_end_date]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
      game[:additional][:popular]  = @count[:menu_id_count] < 151
      image_link_raw               = game[:additional].delete(:image_link_raw)

      if game_add
        sony_game = game_add.sony_game
        if sony_game
          #next if sony_game.deleted || !sony_game.published
          if !sony_game.published
            next
          elsif sony_game.deleted && sony_game.deletedby == settings['user_id']
            sony_game.update(deleted: 0, editedon: Time.current.to_i, editedby: settings['user_id'])
            sony_game.sony_game_additional.update(touched_run_id: run_id)
            @count[:restored] += 1
          elsif sony_game.deleted
            next
          end
        else
          Hamster.logger.error "Основная запись в таблице #{SonyGame.table_name} под ID: `#{game_add.id}` удалена!\n"\
                                 "Удалите остатки в таблицах: #{SonyGameAdditional.table_name}, "\
                                 "#{SonyGameCategories.table_name} или добавте в основную таблицу под этим ID запись."
          next
        end
        update_date(game, game_add, sony_game)
      else
        game[:additional][:run_id]    = run_id
        game[:additional][:source]    = SOURCE
        game[:additional][:site_link] = settings['ps_game'].gsub('en-tr','ru-ua') + game[:additional][:janr]
        game[:additional][:image]     = image_link_raw.sub(/720&h=720/, settings['medium_size'])
        game[:additional][:thumb]     = image_link_raw.sub(/720&h=720/, settings['small_size'])
        game[:additional][:made_in]   = MADE_IN

        crnt_time                  = Time.current.to_i
        game[:main][:longtitle]    = game[:main][:pagetitle]
        game[:main][:parent]       = make_parent(game[:additional][:platform])
        game[:main][:uri]          = make_uri(game[:main][:alias], game[:additional][:platform])
        game[:main][:description]  = form_description(game[:main][:pagetitle])
        game[:main][:publishedon]  = crnt_time
        game[:main][:publishedby]  = settings['user_id']
        game[:main][:createdon]    = crnt_time
        game[:main][:createdby]    = settings['user_id']
        game[:main][:template]     = settings['template_id']
        game[:main][:properties]   = '{"stercseo":{"index":"1","follow":"1","sitemap":"1","priority":"0.5","changefreq":"weekly"}}'
        game[:main][:menuindex]    =  @count[:menu_id_count]
        game[:main][:published]    = 1
        game[:main][:show_in_tree] = 0

        need_category   = check_need_category(game[:additional][:platform])
        game[:category] = { category_id: PARENT_PS4 } if need_category
        game[:intro]    = prepare_intro(game[:main])

        SonyGame.store(game)
        @count[:saved] += 1
      end
    rescue ActiveRecord::RecordInvalid => e
      Hamster.logger.error "#{game[:main][:uri]} || #{e.message}"
    end
  end

  private

  def make_uri(alias_, platform)
    start = platform.downcase.match?(/ps5/) ? @ps5_path : @ps4_path
    "#{start}/#{alias_}"
  end

  def make_parent_path(platform)
    parent = platform == :ps5 ? PARENT_PS5 : PARENT_PS4
    get_parent_alias(parent)
  end

  def get_parent_alias(id)
    path_raw = []
    while id != 0
      sg = SonyGame.find(id)
      path_raw << sg.alias
      id = sg.parent
    end
    path_raw.reverse.join('/')
  end

  def make_parent(platform)
    platform.downcase.match?(/ps5/) ? PARENT_PS5 : PARENT_PS4
  end

  def check_need_category(platform)
    platform.downcase.match?(/ps4/) && platform.downcase.match?(/ps5/)
  end

  def update_date(game, game_add, sony_game)
    check_md5_hash          = game_add[:md5_hash] != game[:additional][:md5_hash]
    start_new_date          = Date.current.prev_month(settings['month_since_release'])
    game[:additional][:new] = game_add[:release] && (game_add[:release] > start_new_date)
    game_add.update(game[:additional]) # For update touched_run_id
    @count[:updated] += 1 if check_md5_hash
    #@count[:skipped] += 1 unless check_md5_hash

    data = { menuindex: @count[:menu_id_count], editedon: Time.current.to_i, editedby: settings['user_id'] }
    sony_game.update(data) && @count[:updated_menu_id] += 1 if @count[:menu_id_count] != sony_game[:menuindex]
  end

  def prepare_intro(game, content=nil)
    data = { intro: game[:pagetitle] + ' ' + game[:longtitle] + ' ' + game[:description] }
    data[:intro] += " #{content}" if content.present?
    data
  end

  def form_description(title)
    <<~DESCR.squeeze(' ').chomp
      Вы искали игру #{title} PS Store Украина. Не знаете где купить? – Конечно же в PS-Ukraine.ru! 100% гарантия 
      от блокировок. Поддержка и консультация, акции и скидки.
    DESCR
  end

  def run
    RunId.new(Run)
  end
end
