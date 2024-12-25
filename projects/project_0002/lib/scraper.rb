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

  def scrape_games_ua
    path_ua    = settings['path_tr'].sub('tr-store', 'ua-store')
    first_page = "#{settings['site']}#{path_ua}1#{settings['params']}"
    last_page  = make_last_page(first_page)
    [*1..last_page].each do |page|
      link = "#{settings['site']}#{path_ua}#{page}#{settings['params']}"
      puts "Page #{page} of #{last_page}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.2..1.5))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_ua")
      @count += 1
    end
  end
end
