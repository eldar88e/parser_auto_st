require_relative '../models/sony_game_ua_run'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_intro'

class Keeper < Hamster::Keeper
  SOURCE     = 3
  FILE_TYPE  = 'image'
  PARENT_PS5 = 21
  PARENT_PS4 = 22
  MADE_IN    = 'Ukraine'

  def initialize
    super
    @run_id = run.run_id
    @count  = { count: 0, menu_id_count: 0, saved: 0, updated: 0, updated_menu_id: 0,
                skipped: 0, deleted: 0, updated_lang: 0, updated_desc: 0 }
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

  def get_games_without_content
    SonyGame.active_games([PARENT_PS5, PARENT_PS4]).where(content: [nil, ''])
  end

  def delete_not_touched
    sg = SonyGame.includes(:sony_game_additional).active_games([PARENT_PS5, PARENT_PS4])
                 .where.not(sony_game_additional: { touched_run_id: run_id })
    sg.update(deleted: 1, deletedon: Time.current.to_i, deletedby: settings['user_id'])
    @count[:deleted] += sg.size
  end

  def get_ps_ids_without_desc_ua
    games_ids       = get_games_without_content.pluck(:id)
    search          = { id: games_ids }
    search[:run_id] = run_id if settings['new_touched_update_desc']
    SonyGameAdditional.where(search).pluck(:id, :janr) # :janr contains Sony game ID
  end

  def save_desc_lang_dd(data, id)
    lang = data.delete(:lang)
    SonyGameAdditional.find(id).update(lang) && @count[:updated_lang] += 1 if lang

    if data[:content]
      data.merge!({ editedon: Time.current.to_i, editedby: settings['user_id'] })
      data[:content].gsub!(/[Бб][Оо][Гг][Ии]?/, 'Human')
      SonyGame.find(id).update(data) && @count[:updated_desc] += 1
    end
  rescue ActiveRecord::StatementInvalid => e
    Hamster.logger.error "ID: #{id} | #{e.message}"
  end

  def get_ps_ids
    params = { rus_voice: 0 }
    if settings['day_lang_all_scrap'] == Date.current.day
      params[:id] = SonyGame.active_games([PARENT_PS5, PARENT_PS4]).order(:menuindex).pluck(:id)
    else
      params[:run_id] = run_id
    end
    SonyGameAdditional.where(params).where.not(janr: [nil, '']).pluck(:id, :janr) # :janr contains Sony game ID
  end

  def save_lang_info(lang, id)
    lang.merge!(touched_run_id: run_id)
    lang[:new] = lang[:release] && lang[:release] > Date.current.prev_month(settings['month_since_release'])
    SonyGameAdditional.find(id).update(lang)
    @count[:updated_lang] += 1
  end

  def save_ua_games(games)
    @ps4_path ||= make_parent_path(:ps4)
    @ps5_path ||= make_parent_path(:ps5)
    games.each do |game|
      @count[:menu_id_count] += 1
      game_db = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url])
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus discount_end_date]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
      game[:additional][:popular]  = @count[:menu_id_count] < 151

      if game_db
        sony_game = SonyGame.find(game_db.id)
        if sony_game
          next if sony_game.deleted || !sony_game.published
        else
          Hamster.logger.error "Основная запись в таблице #{SonyGame.table_name} под ID: `#{game_db.id}` удалена!\n"\
                                 "Удалите остатки в таблицах: #{SonyGameAdditional.table_name}, "\
                                 "#{SonyGameCategories.table_name} или добавте в основную таблицу под этим ID запись."
          next
        end
        update_date(game, game_db, sony_game)
      else
        game[:additional][:run_id]    = run_id
        game[:additional][:source]    = SOURCE
        game[:additional][:site_link] = "https://psprices.com/game/buy/#{game[:additional][:article]}"
        game[:additional][:image]     = game[:additional][:image_link_raw].sub(/720&h=720/, settings['medium_size'])
        game[:additional][:thumb]     = game[:additional][:image_link_raw].sub(/720&h=720/, settings['small_size'])
        game[:additional][:made_in]   = MADE_IN

        crnt_time                  = Time.current.to_i
        game[:main][:longtitle]    = game[:main][:pagetitle]
        game[:main][:description]  = form_description(game[:main][:pagetitle])
        game[:main][:parent]       = make_parent(game[:additional][:platform])
        game[:main][:publishedon]  = crnt_time
        game[:main][:publishedby]  = settings['user_id']
        game[:main][:createdon]    = crnt_time
        game[:main][:createdby]    = settings['user_id']
        game[:main][:template]     = settings['template_id']
        game[:main][:properties]   = '{"stercseo":{"index":"1","follow":"1","sitemap":"1","priority":"0.5","changefreq":"weekly"}}'
        game[:main][:menuindex]    =  @count[:menu_id_count]
        game[:main][:published]    = 1
        game[:main][:uri]          = make_uri(game[:main][:alias], game[:additional][:platform])
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

  def update_date(game, game_db, sony_game)
    start_new_date          = Date.current.prev_month(settings['month_since_release'])
    game[:additional][:new] = !game_db[:release].nil? && game_db[:release] > start_new_date
    game_db.update(game[:additional])
    check_md5_hash = game_db[:md5_hash] != game[:additional][:md5_hash]
    @count[:updated] += 1 if check_md5_hash
    @count[:skipped] += 1 unless check_md5_hash

    data = { menuindex: @count[:menu_id_count], editedon: Time.current.to_i, editedby: settings['user_id'] }
    sony_game.update(data) && @count[:updated_menu_id] += 1 if @count[:menu_id_count] != sony_game[:menuindex]
  end

  def prepare_intro(game, content=nil)
    data = { intro: game[:pagetitle] + ' ' + game[:longtitle] + ' ' + game[:description] }
    data[:intro] += " #{content}" if content.present?
    data
  end

  def form_description(title)
    <<~DESCR
      Вы искали игру #{title} PS Store Украина. Не знаете где купить? - Конечно же в Open-PS.ru! >> 100% гарантия 
      от блокировок. Поддержка и консультация, акции и скидки.
    DESCR
  end

  def run
    RunId.new(SonyGameUaRun)
  end
end
