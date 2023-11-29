require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  SITE    = 'https://psdeals.net'
  PATH_TR = '/tr-store/all-games/'
  PATH_RU = '/ru-store/all-games/'
  PARAMS  = '?sort=most-watchlisted&contentType%5B0%5D=games&contentType%5B1%5D=bundles&contentType%5B2%5D=dlc'
  PS_GAME = 'https://store.playstation.com/en-tr/product/'
  DD_GAME = 'https://ddostup.ru/product/ps-game-'

  def initialize(keeper)
    super
    @count  = 0
    @keeper = keeper
    @debug  = commands[:debug]   #!!!!???????
    @run_id = @keeper.run_id
  end

  attr_reader :count

  def scrape_lang(id)
    url = PS_GAME + id
    sleep rand(1..2)
    get_response(url).body
  end

  def scrape_desc(id)
    url = DD_GAME + id
    #sleep rand(0.5..3)
    get_response(url).body
  end

  def scrape_games_tr
    first_page = "#{SITE}#{PATH_TR}1#{PARAMS}"
    last_page  = make_last_page(first_page)
    notify "Найденно #{last_page} страниц по 36 игр на странице #{first_page}"
    [*1..last_page].each do |page|
      link = "#{SITE}#{PATH_TR}#{page}#{PARAMS}"
      puts "Page #{page} of #{last_page}".green
      game_list = get_response(link).body
      sleep(rand(1..3))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_tr")
      @count += 0
    end
  end

  def scrape_games_ru
    first_page = "#{SITE}#{PATH_RU}1#{PARAMS}"
    last_page  = make_last_page(first_page)
    notify "Найденно #{last_page} страниц по 36 игр на странице #{first_page}"
    [*1..last_page].each do |page|
      link        = "#{SITE}#{PATH_RU}#{page}"
      game_list   = get_response(link).body
      parser      = Parser.new(html: game_list)
      games_links = parser.parse_games_list
      games_links.each_with_index do |path, index|
        puts "List page: #{page}, game page: #{index}".green
        url  = SITE + path
        game = get_response(url).body
        name = MD5Hash.new(columns: %i[path]).generate({ path: path })
        peon.put(file: "#{name}.html", content: game, subfolder: "#{run_id}_games_ru/game_list_#{page}")
        sleep rand(1..3)
        @count += 0
      end
    end
  end

  private

  attr_reader :run_id

  def make_last_page(first_page)
    game_list = get_response(first_page).body
    parser    = Parser.new(html: game_list)
    parser.get_last_page
  end

  def get_response(link)
    connect_to(link, ssl_verify: false)
  end

  def notify(message, color=:green, method_=:info)
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts message.send(color) if @debug
  end
end
