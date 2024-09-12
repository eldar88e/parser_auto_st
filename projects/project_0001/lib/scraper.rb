require_relative '../lib/parser'
require_relative '../../../concerns/game_modx/scraper'

class Scraper < Hamster::Scraper
  include GameModx::Scraper

  def initialize(**args)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    @keeper   = args[:keeper]
    @settings = args[:settings]
    @debug    = commands[:debug]
    @run_id   = @keeper.run_id
  end

  def scrape_games_tr
    first_page = "#{settings['site']}#{settings['path_tr']}1#{settings['params']}"
    last_page  = make_last_page(first_page)
    puts "Found #{last_page} pages with a list of games (36 games/page) on the website #{first_page}" if @debug
    [*1..last_page].each do |page|
      link = "#{settings['site']}#{settings['path_tr']}#{page}#{settings['params']}"
      puts "Page #{page} of #{last_page}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.3..2.3))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_tr")
      @count += 1
    end
  end

  def scrape_desc(id)
    url = settings['dd_game'] + id
    sleep rand(0.5..2.5)
    get_response(url).body
  end
end
