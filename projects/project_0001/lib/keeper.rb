require_relative '../models/sony_game_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_intro'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game_additional_file'

class Keeper < Hamster::Keeper
  SOURCE    = 3
  FILE_TYPE = 'image'
  MADE_IN   = 'Turkish'

  def initialize
    super
    @count           = 0
    @menu_id_count   = 0
    @run_id          = run.run_id
    @saved           = 0
    @updated         = 0
    @updated_menu_id = 0
    @skipped         = 0
    @deleted         = 0
    @updated_lang    = 0
    @updated_desc    = 0
  end

  attr_reader :run_id, :saved, :updated, :skipped, :updated_lang, :updated_menu_id, :updated_desc, :deleted
  attr_accessor :count

  def status=(new_status)
    run.status = new_status
  end

  def status
    run.status
  end

  def finish
    run.finish
  end

  def list_last_popular_game(limit, parent)
    SonyGame.includes(:sony_game_additional, :sony_game_intro).active_games(parent).order(menuindex: :asc).limit(limit)
  end

  def get_games_without_content
    SonyGame.active_games([settings['parent_ps5'], settings['parent_ps4']]).where(content: [nil, ''])
  end

  def delete_not_touched
    #sg = SonyGame.active_games([settings['parent_ps5'], settings['parent_ps4']]).pluck(:id)
    #sga = SonyGameAdditional.where(id: sg).where.not(touched_run_id: run_id)
    sg = SonyGame.includes(:sony_game_additional).active_games([settings['parent_ps5'], settings['parent_ps4']])
                 .where.not(sony_game_additional: { touched_run_id: run_id })
    sg.update(deleted: 1, deletedon: Time.current.to_i, deletedby: settings['user_id'])
    @deleted += sg.size
  end

  def get_ps_ids_without_desc
    games_ids       = get_games_without_content.pluck(:id)
    search          = { id: games_ids }
    search[:run_id] = run_id if settings['new_touched_update_desc']
    SonyGameAdditional.where(search).pluck(:id, :janr) # :janr contains Sony game ID
  end

  def save_desc(data)
    game = get_games_without_content.find { |i| i[:alias].gsub(/-\d+\z/, '') == data[:alias] }
    return unless game

    game.update(content: data[:desc], editedon: Time.current.to_i, editedby: settings['user_id']) && @updated_desc += 1
  end

  def save_desc_dd(data, id)
    data.merge!({ editedon: Time.current.to_i, editedby: settings['user_id'] })
    begin
      SonyGame.find(id).update(data) && @updated_desc += 1
    rescue ActiveRecord::StatementInvalid => e
      Hamster.logger.error "ID: #{id} | #{e.message}"
    end
  end

  def get_ps_ids
    params = { rus_voice: 0 }
    if settings['day_lang_all_scrap'] == Date.current.day
      params[:id] = SonyGame.active_games([settings['parent_ps5'], settings['parent_ps4']])
                            .order(:menuindex).pluck(:id)
    else
      params[:run_id] = run_id
    end
    SonyGameAdditional.where(params).where.not(janr: [nil, '']).limit(settings['limit_upd_lang']).pluck(:id, :janr) # :janr contains Sony game ID
  end

  def save_lang_info(lang, id)
    lang.merge!(touched_run_id: run_id)
    lang[:new] = lang[:release] && lang[:release] > Date.current.prev_month(settings['month_since_release'])
    SonyGameAdditional.find(id).update(lang)
    @updated_lang += 1
  end

  def save_games(games)
    @ps4_path ||= make_parent_path(:ps4)
    @ps5_path ||= make_parent_path(:ps5)
    games.each do |game|
      @menu_id_count += 1
      game_add = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url])
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus discount_end_date]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
      game[:additional][:popular]  = @menu_id_count < 151

      if game_add
        sony_game = SonyGame.find(game_add.id)
        if sony_game
          next if sony_game.deleted || !sony_game.published
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
        #game[:additional][:site_link] = "https://psprices.com/game/buy/#{game[:additional][:article]}"
        game[:additional][:site_link] = settings['ps_game'] + game[:additional][:janr]
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
        game[:main][:menuindex]    = @menu_id_count
        game[:main][:published]    = 1
        game[:main][:uri]          = make_uri(game[:main][:alias], game[:additional][:platform])
        game[:main][:show_in_tree] = 0

        need_category   = check_need_category(game[:additional][:platform])
        game[:category] = { category_id: settings['parent_ps4'] } if need_category
        game[:intro]    = prepare_intro(game[:main])

        SonyGame.store(game)
        @saved += 1
      end
    end
  end

  private

  def make_uri(alias_, platform)
    start = platform.downcase.match?(/ps5/) ? @ps5_path : @ps4_path
    "#{start}/#{alias_}"
  end

  def make_parent_path(platform)
    if platform == :ps5
      get_parent_alias(settings['parent_ps5'])
    else
      get_parent_alias(settings['parent_ps4'])
    end
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
    platform.downcase.match?(/ps5/) ? settings['parent_ps5'] : settings['parent_ps4']
  end

  def check_need_category(platform)
    platform.downcase.match?(/ps4/) && platform.downcase.match?(/ps5/)
  end

  def update_date(game, game_add, sony_game)
    check_md5_hash          = game_add[:md5_hash] != game[:additional][:md5_hash]
    start_new_date          = Date.current.prev_month(settings['month_since_release'])
    game[:additional][:new] = game_add[:release] && game_add[:release] > start_new_date
    game_add.update(game[:additional])
    @updated += 1 if check_md5_hash
    #@skipped += 1 unless check_md5_hash

    data = { menuindex: @menu_id_count, editedon: Time.current.to_i, editedby: settings['user_id'] }
    sony_game.update(data) && @updated_menu_id += 1 if @menu_id_count != sony_game[:menuindex]
  end

  def prepare_intro(game, content=nil)
    data = { intro: game[:pagetitle] + ' ' + game[:longtitle] + ' ' + game[:description] }
    data[:intro] += " #{content}" if content.present?
    data
  end

  def save_image_info(id, img)
    crnt_time = Time.current
    md5       = MD5Hash.new(columns: %i[:time])
    md5_hash  = md5.generate(time: crnt_time)
    file      = {}

    file[:source]     = SOURCE
    file[:name]       = md5_hash
    file[:file]       = "#{md5_hash}.jpg"
    file[:type]       = FILE_TYPE
    file[:createdon]  = crnt_time
    file[:createdby]  = settings['user_id']
    file[:url]        = img
    file[:product_id] = id

    parent   = 0
    paths    = %w[/ /100x98/ /520x508/]
    new_file = {}
    new_file.merge!(file)
    paths.each_with_index do |item, idx|
      new_file.merge!(path: "#{id}#{item}", parent: parent)
      if item == paths[1]
        new_file[:url] = file[:url].sub(/720&h=720/, settings['small_size'])
      elsif item == paths[2]
        new_file[:url] = file[:url].sub(/720&h=720/, settings['medium_size'])
      end
      sga    = SonyGameAdditionalFile.create!(new_file)
      parent = sga.id if idx.zero?
    end
  end

  def form_description(title)
    <<~DESCR.gsub(/\n/, '')
      Игра #{title}. Купить игру #{title[0..100]} сегодня по выгодной цене. Доставка - СПБ, Москва и вся Россия. 
      Вы искали игру #{title[0..100]} где купить? - Конечно же в Open-PS.ru! >> 100% гарантия от блокировок. 
      Поддержка и консультация, акции и скидки.
    DESCR
  end

  def run
    RunId.new(SonyGameRun)
  end
end
