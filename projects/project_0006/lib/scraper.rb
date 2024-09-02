require_relative '../lib/parser'
require_relative '../../../concerns/game_modx/scraper'

class Scraper < Hamster::Scraper
  include GameModx::Scraper

  MIN_PRICE = 1 # это примерно 125 на 31.08.2024

  def initialize(**args)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    @keeper   = args[:keeper]
    @settings = args[:settings]
    @debug    = commands[:debug]
    @run_id   = @keeper.run_id
  end

  def scrape_games_in
    path_in    = settings['path_tr'].sub('tr-store', 'in-store')
    params     = settings['params'].sub('&minPrice=15', "&minPrice=#{MIN_PRICE}")
    first_page = "#{settings['site']}#{path_in}1#{params}"
    last_page  = make_last_page(first_page)
    [*1..last_page].each do |page|
      link = "#{settings['site']}#{path_in}#{page}#{params}"
      puts "Page #{page} of #{last_page}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.2..1.5))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_in")
      @count += 1
    end
  end
end
