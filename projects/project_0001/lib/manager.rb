require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  SITE = 'https://psdeals.net'

  def initialize
    super
    @keeper = Keeper.new
  end

  def download
    scraper = Scraper.new(keeper)
    if commands[:tr]
      scraper.scrape_games_tr
    elsif commands[:ru]
      scraper.scrape_games_ru
    end
    puts "Scraping finish".green
  end

  def store
    keeper.status = 'parsing'
    run_id        = keeper.run_id
    list_pages = peon.give_list(subfolder: "#{run_id}_games_tr")
    list_pages.each do |name|
      file      = peon.give(file: name, subfolder: "#{run_id}_games_tr")
      parser    = Parser.new(html: file)
      list_info = parser.parse_list_info
      keeper.save_games(list_info)
    end
    #keeper.finish
    puts 'Finish'.green
  end

  private

  attr_reader :keeper
end
