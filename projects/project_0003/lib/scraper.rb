require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  LAST_PAGE = 20

  def initialize(keeper)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    @keeper   = keeper
    @debug    = commands[:debug]
    @run_id   = @keeper.run_id
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

  def scrape_games_ua
    path_ua = settings['path_tr'].sub('tr-store', 'ua-store')
    [*1..LAST_PAGE].each do |page|
      link = "#{settings['site']}#{path_ua}#{page}#{settings['params']}"
      puts "Page #{page} of #{LAST_PAGE}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.2..1.5))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_ua")
      @count += 1
    end
  end

  def scrape_games_desc
    path_ua = settings['path_tr'].sub('tr-store', 'ua-store')
    [*1..LAST_PAGE].each do |page|
      link        = "#{settings['site']}#{path_ua}#{page}"
      game_list   = get_response(link).body
      parser      = Parser.new(html: game_list)
      games_links = parser.parse_games_list
      games_links.each_with_index do |path, index|
        puts "List page: #{page}, game page: #{index}".green if @debug
        url  = settings['site'] + path
        game = get_response(url).body
        name = MD5Hash.new(columns: %i[path]).generate({ path: path })
        peon.put(file: "#{name}.html", content: game, subfolder: "#{run_id}_games_ua/game_list_#{page}")
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
    headers = { 'Referer' => @referers.sample, 'Accept-Language' => 'ua-UA' }
    connect_to(link, ssl_verify: false, headers: headers)
  rescue => e
    puts e
    Hamster.report message: e.message + "\n #{link}"
    binding.pry
  end
end
