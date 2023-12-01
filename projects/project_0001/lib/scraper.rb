require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @referer = YAML.load_file('referer.yml')['referer']
    @count   = 0
    @keeper  = keeper
    @debug   = commands[:debug]
    @run_id  = @keeper.run_id
  end

  attr_reader :count

  def scrape_lang(id)
    url = settings['ps_game'] + id
    sleep rand(0.2..2.1)
    get_response(url).body
  end

  def scrape_desc(id)
    url = settings['dd_game'] + id
    sleep rand(0.2..2.1)
    get_response(url).body
  end

  def scrape_games_tr
    first_page = "#{settings['site']}#{settings['path_tr']}1#{settings['params']}"
    last_page  = make_last_page(first_page)
    notify "Found #{last_page} pages with a list of games (36 games/page) on the website #{first_page}" if @debug
    [*1..last_page].each do |page|
      link = "#{settings['site']}#{settings['path_tr']}#{page}#{settings['params']}"
      puts "Page #{page} of #{last_page}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.3..2.5))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_tr")
      @count += 1
    end
  end

  def scrape_games_ru
    first_page = "#{settings['site']}#{settings['path_ru']}1#{settings['params']}"
    last_page  = make_last_page(first_page)
    notify "Найденно #{last_page} страниц по 36 игр на странице #{first_page}"
    [*1..last_page].each do |page|
      link        = "#{settings['site']}#{settings['path_ru']}#{page}"
      game_list   = get_response(link).body
      parser      = Parser.new(html: game_list)
      games_links = parser.parse_games_list
      games_links.each_with_index do |path, index|
        puts "List page: #{page}, game page: #{index}".green if @debug
        url  = settings['site'] + path
        game = get_response(url).body
        name = MD5Hash.new(columns: %i[path]).generate({ path: path })
        peon.put(file: "#{name}.html", content: game, subfolder: "#{run_id}_games_ru/game_list_#{page}")
        sleep rand(1..3)
        @count += 1
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
    referer                    = @referer.sample
    headers                    = { 'Referer' => referer }
    headers['Accept-Language'] = 'tr-TR' if settings['accept_language_tr']
    connect_to(link, ssl_verify: false, headers: headers)
  end

  def notify(message, color=:green, method_=:info)
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts message.send(color) if @debug
  end
end
