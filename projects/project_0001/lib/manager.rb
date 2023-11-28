require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
    @debug  = commands[:debug]
  end

  def download
    notify 'Scraping started'
    scraper = Scraper.new(keeper)
    if commands[:tr]
      scraper.scrape_games_tr
    elsif commands[:ru]
      scraper.scrape_games_ru
    end
    notify "Scraping finish!\nScraped: #{scraper.count} pages"
  end

  def store
    parse_save_lang
    binding.pry
    notify 'Parsing started'
    keeper.status = 'parsing'
    run_id        = keeper.run_id
    list_pages    = peon.give_list(subfolder: "#{run_id}_games_tr").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count  = 0
    othr_pl_count = 0
    not_prc_count = 0
    list_pages.each_with_index do |name, idx|
      puts "#{name}".green
      file      = peon.give(file: name, subfolder: "#{run_id}_games_tr")
      parser    = Parser.new(html: file)
      list_info = parser.parse_list_info
      parser_count  += parser.parsed
      othr_pl_count += parser.other_platform
      not_prc_count += parser.not_price
      keeper.save_games(list_info, idx)
    end
    #keeper.finish
    message = "Finish store!"
    message << "\nSaved: #{keeper.saved} games;" unless keeper.saved.zero?
    message << "\nUpdated: #{keeper.updated} games;" unless keeper.updated.zero?
    message << "\nSkipped: #{keeper.skipped} games;" unless keeper.skipped.zero?
    message << "\nNot parsed other platform: #{othr_pl_count} games;" unless othr_pl_count.zero?
    message << "\nNot parsed without price: #{not_prc_count} games;" unless not_prc_count.zero?
    message << "\nParsed: #{parser_count} games." unless parser_count.zero?

    notify message
  end

  private

  attr_reader :keeper

  def parse_save_lang
    ps_ids  = keeper.get_ps_ids
    scraper = Scraper.new(keeper)
    ps_ids.each do |id|
      page   = scraper.scrape_lang(id[1])
      parser = Parser.new(html: page)
      lang   = parser.parse_lang
      next if lang.nil?

      keeper.save_lang_info(lang, id[0])
    end
  end

  def notify(message, color=:green, method_=:info)
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts message.send(color) if @debug
  end
end
