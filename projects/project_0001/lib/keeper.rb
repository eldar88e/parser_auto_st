require_relative '../models/sony_game_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game_additional_file'

class Keeper
  PARENT         = 218
  TEMPLATE_ID    = 10
  GAMES_PER_PAGE = 36
  SOURCE         = 3
  USER_ID        = 1064
  FILE_TYPE      = 'image'
  SMALL_SIZE     = '50&h=50'
  MIDDLE_SIZE    = '320&h=320'
  PATH_CATALOG   = 'katalog-tovarov/games/'
  # https://store.playstation.com/store/api/chihiro/00_09_000/container/TR/tr/99/EP1018-PPSA07571_00-MKONEPREMIUM0000/0/image?_version=00_09_000&platform=chihiro&bg_color=000000&opacity=100&w=720&h=720
  # https://store.playstation.com/en-tr/product/EP9000-CUSA00917_00-U4UTLLBUNDLE0000

  def initialize
    @count   = 0
    @run_id  = run.run_id
    @saved   = 0
    @updated = 0
    @skipped = 0
  end

  attr_reader :run_id, :saved, :updated, :skipped
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

  def save_games(games, page)
    count = page > 0 ? GAMES_PER_PAGE * page : 0
    games.each do |game|
      count += 1
      game_db = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url]) # , deleted: 0
      next if game_db && game_db[:deleted] == 1

      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))

      if game_db
        check_md5_hash = game_db[:md5_hash] != game[:additional][:md5_hash]
        game_db.update(game[:additional]) if check_md5_hash
        data            = { menuindex: count, editedon: Time.current.to_i, editedby: USER_ID }
        sony_game       = SonyGame.find(game_db.id)
        check_menuindex = count != sony_game[:menuindex]
        sony_game.update(data) if check_menuindex
        if check_md5_hash || check_menuindex
          @updated += 1
        else
          @skipped += 1
        end
      else
        game[:additional][:run_id]    = run_id
        game[:additional][:source]    = SOURCE
        game[:additional][:site_link] = "https://psprices.com/game/buy/#{game[:additional][:article]}"
        game[:additional][:image]     = game[:additional][:image_link_raw]
        game[:additional][:thumb]     = game[:additional][:image_link_raw].sub(/720&h=720/, SMALL_SIZE)

        crnt_time                  = Time.current
        game[:main][:longtitle]    = game[:main][:pagetitle]
        game[:main][:description]  = form_description(game[:main][:pagetitle])
        game[:main][:parent]       = PARENT
        game[:main][:publishedon]  = crnt_time.to_i
        game[:main][:publishedby]  = USER_ID
        game[:main][:createdon]    = crnt_time.to_i
        game[:main][:createdby]    = USER_ID
        game[:main][:template]     = TEMPLATE_ID
        game[:main][:properties]   = '{"stercseo":{"index":"1","follow":"1","sitemap":"1","priority":"0.5","changefreq":"weekly"}}'
        game[:main][:menuindex]    = count
        game[:main][:published]    = 1
        game[:main][:uri]          = "#{PATH_CATALOG}#{game[:main][:alias]}"
        game[:main][:show_in_tree] = 0

        sony_game_id = SonyGame.store(game)

        save_image_info(sony_game_id, game[:additional][:image_link_raw])
        @saved += 1
      end
    rescue => e
      notify e.message
      binding.pry
      retry
    end
    binding.pry
  end

  private

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
    file[:createdby]  = USER_ID
    file[:url]        = img
    file[:product_id] = id

    parent   = 0
    paths    = %w[/ /100x98/ /520x508/]
    new_file = {}
    new_file.merge!(file)
    paths.each_with_index do |item, idx|
      new_file.merge!(path: "#{id}#{item}", parent: parent)
      if item == paths[1]
        new_file[:url] = file[:url].sub(/720&h=720/, SMALL_SIZE)
      elsif item == paths[2]
        new_file[:url] = file[:url].sub(/720&h=720/, MIDDLE_SIZE)
      end

      begin
        binding.pry
        #SonyGameAdditionalFile.create!(new_file)
      rescue TypeError => e
        # e
      end

      parent = SonyGameAdditionalFile.last.id if idx.zero?
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

  def correct_date(date)
    year_raw = date.match(/-\d{4}$/).to_s
    date.sub!(year_raw, '')
    (year_raw.sub('-', '') + '-' + date).to_date
  end

  def notify(message, color=:green, method_=:info)
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts message.send(color) if @debug
  end
end
