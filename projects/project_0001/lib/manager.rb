require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  SITE = 'https://psdeals.net'

  def initialize
    super
    @keeper = Keeper.new
    @debug  = commands[:debug]
  end

  def download
    scraper = Scraper.new(keeper)
    if commands[:tr]
      scraper.scrape_games_tr
    elsif commands[:ru]
      scraper.scrape_games_ru
    end
    notify "Scraping finish"
  end

  def store
    keeper.status = 'parsing'
    run_id        = keeper.run_id
    list_pages = peon.give_list(subfolder: "#{run_id}_games_tr").sort_by { |name| name.scan(/\d+/).first.to_i }
    list_pages.each do |name|
      puts "#{name}".green
      file      = peon.give(file: name, subfolder: "#{run_id}_games_tr")
      parser    = Parser.new(html: file)
      list_info = parser.parse_list_info
      keeper.save_games(list_info)
    end
    #keeper.finish
    notify 'Finish store'
  end

  private

  attr_reader :keeper

  def notify(message, color=:green, method_=:info)
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts message.send(color) if @debug
  end
end
