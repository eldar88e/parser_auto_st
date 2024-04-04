require_relative '../models/ua_run'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_intro'
require_relative '../models/content'
require_relative '../models/product'

class Keeper < Hamster::Keeper
  SOURCE     = 3
  PARENT_PS5 = 21
  PARENT_PS4 = 22
  MADE_IN    = 'Ukraine'

  def initialize(quantity)
    super
    @run_id = run.run_id
    @count  = { count: 0, menu_id_count: 0, saved: 0, updated: 0, updated_menu_id: 0,
                skipped: 0, deleted: 0, updated_lang: 0, updated_desc: 0 }
    @quantity = quantity
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
    rescue => e
      binding.pry
    rescue ActiveRecord::RecordInvalid => e
      binding.pry
      Hamster.logger.error "#{game[12]} || #{e.message}"
    end
  end

  def delete_not_touched
    sg = SonyGame.includes(:sony_game_additional).active_games([PARENT_PS5, PARENT_PS4])
                 .where.not(sony_game_additional: { touched_run_id: run_id })
    sg.update(deleted: 1, deletedon: Time.current.to_i, deletedby: settings['user_id'])
    @count[:deleted] += sg.size
  end

  private

  def get_top_games(game_key)
    Content.order(:menuindex).active_contents([PARENT_PS5, PARENT_PS4])
           .includes(:product).limit(@quantity).pluck(*game_key)
  end

  def save_ua_games(game)
    @ps4_path ||= make_parent_path(:ps4)
    @ps5_path ||= make_parent_path(:ps5)
    @count[:menu_id_count] += 1
    game_add = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url])
    game[:additional][:touched_run_id] = run_id
    keys = %i[data_source_url price old_price price_bonus discount_end_date]
    md5  = MD5Hash.new(columns: keys)
    game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
    game[:additional][:popular]  = @count[:menu_id_count] < 151

    if game_add
      sony_game = game_add.sony_game
      if sony_game
        return if sony_game.deleted || !sony_game.published
      else
        Hamster.logger.error "Основная запись в таблице #{SonyGame.table_name} под ID: `#{game_add.id}` удалена!\n"\
                               "Удалите остатки в таблицах: #{SonyGameAdditional.table_name}, "\
                               "#{SonyGameCategories.table_name} или добавте в основную таблицу под этим ID запись."
        return
      end
      update_date(game, game_add, sony_game)
    else
      game[:additional][:run_id]    = run_id
      game[:additional][:source]    = SOURCE
      game[:additional][:site_link] = settings['ps_game'].gsub('en-tr','ru-ua') + game[:additional][:janr]
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
  end

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
    game[:additional][:new] = game_add[:release] && game_add[:release] > start_new_date
    game_add.update(game[:additional])
    @count[:updated] += 1 if check_md5_hash
    #@count[:skipped] += 1 unless check_md5_hash

    ## убрать content из data
    data = { menuindex: @count[:menu_id_count], editedon: Time.current.to_i, editedby: settings['user_id'], content: game[:main][:content] }
    ###
    if sony_game.update(data)
      @count[:updated_menu_id] += 1 #if @count[:menu_id_count] != sony_game[:menuindex]
    else
      binding.pry
    end
  rescue => e
    binding.pry
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
    RunId.new(UaRun)
  end
end
