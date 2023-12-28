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

  private

  attr_reader :run_id

  def get_response(link)
    headers = { 'Referer' => @referers.sample, 'Accept-Language' => 'ua-UA' }
    connect_to(link, ssl_verify: false, headers: headers)
  rescue => e
    puts e
    Hamster.report message: e.message + "\n #{link}"
    binding.pry
  end
end
