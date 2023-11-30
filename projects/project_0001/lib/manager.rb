require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require 'net/ftp'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
    @debug  = commands[:debug]
    @pages  = 0
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
    notify 'Parsing started'
    keeper.status = 'parsing'

    if commands[:lang]
      size = commands[:lang].is_a?(Integer) ? commands[:lang] : nil
      parse_save_lang(size)
      notify "Completed parsing and updating of language information for #{keeper.updated_lang} game(s)"
      return
    end

    if commands[:desc]
      #parse_save_desc
      parse_save_desc_dd
      notify "Completed parsing and updating of description for #{keeper.updated_lang} game(s)"
      return
    end

    parser_count, othr_pl_count, not_prc_count = parse_save_main
    #parse_save_lang
    #keeper.finish
    message = make_message(othr_pl_count, not_prc_count, parser_count)
    notify message
    clear_cache unless keeper.saved.zero?
  end

  private

  attr_reader :keeper

  def clear_cache
    ftp_host = 'eldarap0.beget.tech'
    ftp_user = 'eldarap0_openps'
    ftp_pass = '&4&J&Stx'

    Net::FTP.open(ftp_host, ftp_user, ftp_pass) do |ftp|
      ftp.chdir('/core/cache/context_settings/web')
      filename_to_delete = 'context.cache.php'
      ftp.delete(filename_to_delete)
      notify "The file '#{filename_to_delete}' was deleted."
    rescue => e
      Hamster.logger.error e
      notify "Please delete the ModX cache file manually!"
    end
  end

  def parse_save_desc_dd
    ps_ids  = keeper.get_ps_ids_without_desc
    scraper = Scraper.new(keeper)
    ps_ids.each do |id|
      page   = scraper.scrape_desc(id[1])
      parser = Parser.new(html: page)
      desc   = parser.parse_desc_dd
      next unless desc

      keeper.save_desc_dd(desc, id[0])
    end
  end

  def parse_save_main
    run_id     = keeper.run_id
    list_pages = peon.give_list(subfolder: "#{run_id}_games_tr").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count, othr_pl_count, not_prc_count = [0, 0, 0]
    list_pages.each_with_index do |name, idx|
      limit = commands[:count] && commands[:count].is_a?(Integer) ? commands[:count] : 5
      break if idx > limit

      puts "#{name}".green
      file      = peon.give(file: name, subfolder: "#{run_id}_games_tr")
      parser    = Parser.new(html: file)
      list_info = parser.parse_list_info
      parser_count  += parser.parsed
      othr_pl_count += parser.other_platform
      not_prc_count += parser.not_price
      keeper.save_games(list_info, idx)
      @pages += 1
    end
    [parser_count, othr_pl_count, not_prc_count]
  end

  def parse_save_desc
    run_id     = keeper.run_id
    list_pages = peon.list(subfolder: "#{run_id}_games_ru").sort_by { |name| name.scan(/\d+/).first.to_i }
    list_pages.each do |name_list_page|
      list_games = peon.list(subfolder: "#{run_id}_games_ru/#{name_list_page}")
      list_games.each do |name|
        puts "#{name}".green
        file      = peon.give(file: name, subfolder: "#{run_id}_games_ru/#{name_list_page}")
        parser    = Parser.new(html: file)
        list_info = parser.parse_game_desc
        keeper.save_desc(list_info) if list_info
      end
    end
  end

  def make_message(othr_pl_count, not_prc_count, parser_count)
    message = "Finish store!"
    message << "\nSaved: #{keeper.saved} games;" unless keeper.saved.zero?
    message << "\nUpdated: #{keeper.updated} games;" unless keeper.updated.zero?
    message << "\nSkipped: #{keeper.skipped} games;" unless keeper.skipped.zero?
    message << "\nNot parsed other platform: #{othr_pl_count} games;" unless othr_pl_count.zero?
    message << "\nNot parsed without price: #{not_prc_count} games;" unless not_prc_count.zero?
    message << "\nParsed: #{@pages} pages, #{parser_count} games." unless parser_count.zero?
    message << "\nParsed and updated of lang info for #{keeper.updated_lang} game(s)" unless keeper.updated_lang.zero?
    message
  end

  def parse_save_lang(limit=nil)
    ps_ids  = keeper.get_ps_ids(limit)
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
