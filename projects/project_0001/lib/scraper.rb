require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @count  = 0
    @keeper = keeper
    @debug  = commands[:debug]   #!!!!???????
    @run_id = @keeper.run_id
  end

  attr_reader :count

  def scrape_games_tr
    [*1..368].each do |page|
      puts "Page of #{page}".green
      link      = "#{SITE}/tr-store/all-games/#{page}"
      game_list = get_response(link).body
      sleep(rand(1..3))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{1}_games_tr")   #run_id hard code)
    end
  end

  def scrape_games_ru
    [*1..358].each do |page|
      link        = "#{SITE}/ru-store/all-games/#{page}"
      game_list   = get_response(link).body
      parser      = Parser.new(html: game_list)
      games_links = parser.parse_games_list
      games_links.each_with_index do |path, index|
        puts "List page: #{page}, game page: #{index}".green
        url  = SITE + path
        game = get_response(url).body
        name = MD5Hash.new(columns: %i[path]).generate({ path: path })
        peon.put(file: "#{name}.html", content: game, subfolder: "#{1}_games_ru/game_list_#{page}")  #run_id hard code)
        sleep rand(3..7)
      end
    end
  end

  private

  def get_response(link)
    connect_to(link, ssl_verify: false)
  end
end
