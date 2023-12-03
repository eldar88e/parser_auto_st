require_relative '../models/sony_game_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_intro'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game_additional_file'

class Keeper < Hamster::Keeper
  SOURCE = 3

  def initialize
    super
    @count           = 0
    @menu_id_count   = 0
    @run_id          = run.run_id
    @saved           = 0
    @updated         = 0
    @updated_menu_id = 0
    @skipped         = 0
    @updated_lang    = 0
    @updated_desc    = 0
  end

  attr_reader :run_id, :saved, :updated, :skipped, :updated_lang, :updated_menu_id, :updated_desc
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

  def get_games_without_content
    SonyGame.active_games([settings['parent_ps5'], settings['parent_ps4']]).where(content: [nil, ''])
  end

  def get_ps_ids_without_desc
    sg     = get_games_without_content.pluck(:id)
    search = { id: sg }
    search[:touched_run_id] = run_id if settings['new_touched_update_desc']
    SonyGameAdditional.where(search).pluck(:id, :janr) # :janr contains Sony game ID
  end

  def save_desc(data)
    return unless data

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
    sg_id = SonyGame.active_games([settings['parent_ps5'], settings['parent_ps4']]).order(:menuindex)
                    .limit(settings['limit_upd_lang']).pluck(:id)
    params                  = { id: sg_id }
    params[:touched_run_id] = run_id if settings['day_lang_all_scrap'] != Date.current.day
    SonyGameAdditional.where(params).where.not(janr: [nil, '']).pluck(:id, :janr) # :janr contains Sony game ID
  end

  def save_lang_info(lang, id)
    lang.merge!(touched_run_id: run_id)
    lang[:new] = true if lang[:release] && lang[:release] > Date.current.prev_month(settings['month_since_release'])
    SonyGameAdditional.find(id).update(lang)
    @updated_lang += 1
  end

  def save_games(games)
    games.each do |game|
      @menu_id_count += 1
      game_db = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url])
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
      game[:additional][:popular]  = @menu_id_count < 151 ? true : false

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
        game[:additional][:image]     = game[:additional][:image_link_raw]
        game[:additional][:thumb]     = game[:additional][:image_link_raw].sub(/720&h=720/, settings['small_size'])

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
        game[:main][:uri]          = "#{settings['path_catalog']}#{game[:main][:alias]}"
        game[:main][:show_in_tree] = 0

        need_category   = check_need_category(game[:additional][:platform])
        game[:category] = { category_id: settings['parent_ps4'] } if need_category
        game[:intro]    = prepare_intro(game[:main])

        SonyGame.store(game)
        @saved += 1
      end
    rescue => e
      Hamster.logger.error e.message
    end
  end

  private

  def make_parent(platform)
    platform.downcase.match?(/ps5/) ? settings['parent_ps5'] : settings['parent_ps4']
  end

  def check_need_category(platform)
    platform.downcase.match?(/ps4/) && platform.downcase.match?(/ps5/)
  end

  def update_date(game, game_db, sony_game)
    check_md5_hash          = game_db[:md5_hash] != game[:additional][:md5_hash]
    release                 = game[:additional][:release]
    game[:additional][:new] = release && release > Date.current.prev_month(settings['month_since_release']) ? true : false
    binding.pry
    game_db.update(game[:additional]) && @updated += 1 if check_md5_hash
    data          = { menuindex: @menu_id_count, editedon: Time.current.to_i, editedby: settings['user_id'] }
    check_menu_id = @menu_id_count != sony_game[:menuindex]
    sony_game.update(data) && @updated_menu_id += 1 if check_menu_id

    @skipped += 1 if !check_md5_hash && !check_menu_id
  end

  def prepare_intro(game)
   { intro: game[:pagetitle] + ' ' + game[:longtitle] + ' ' + game[:description] }
  end

  def save_image_info(id, img)
    crnt_time = Time.current
    md5       = MD5Hash.new(columns: %i[:time])
    md5_hash  = md5.generate(time: crnt_time)
    file      = {}

    file[:source]     = SOURCE
    file[:name]       = md5_hash
    file[:file]       = "#{md5_hash}.jpg"
    file[:type]       = settings['file_type']
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
        new_file[:url] = file[:url].sub(/720&h=720/, settings['middle_size'])
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
