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
    if commands[:desc]
      scraper_ru = Scraper.new(keeper)
      scraper_ru.scrape_games_desc
      notify "Scraping finish!\nScraped: #{scraper_ru.count} pages." if @debug
      return
    end

    peon.move_all_to_trash
    puts 'The Store has been emptied.' if @debug
    peon.throw_trash(10)
    puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping started' if @debug
    scraper = Scraper.new(keeper)
    scraper.scrape_games_ua
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing started' if @debug
    keeper.status = 'parsing'

    if commands[:lang]
      parse_save_lang
      return
    elsif commands[:desc]
      #parse_save_desc_ru
      parse_save_desc_dd
      return
    end

    parse_save_main
    parse_save_lang    if !keeper.count[:saved].zero? || settings['day_lang_all_scrap'] == Date.current.day
    parse_save_desc_dd unless keeper.count[:saved].zero?
    keeper.delete_not_touched
    notify "Deleted: #{keeper.deleted} old games" if keeper.deleted > 0
    cleared_cache = false
    if !keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.deleted.zero?
      clear_cache
      cleared_cache = true
    end
    keeper.finish
    notify 'The parser completed its work successfully!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    clear_cache if !cleared_cache && (!keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.deleted.zero?)
  end

  private

  attr_reader :keeper

  def clear_cache
    ftp_host = ENV.fetch('FTP_HOST')
    ftp_user = ENV.fetch('FTP_LOGIN')
    ftp_pass = ENV.fetch('FTP_PASS')

    Net::FTP.open(ftp_host, ftp_user, ftp_pass) do |ftp|
      ftp.chdir('/core/cache/context_settings/web')
      delete_files(ftp)
      ftp.chdir('/core/cache/resource/web/resources')
      delete_files(ftp)
    end
    notify "The cache has been emptied." if @debug
  rescue => e
    message = "Please delete the ModX cache file manually!\nError: #{e.message}"
    notify(message, :red, :error)
  end

  def delete_files(ftp)
    list = ftp.nlst
    list.each do |i|
      try = 0
      begin
        try += 1
        ftp.delete(i)
      rescue Net::FTPPermError => e
        Hamster.logger.error e.message
        sleep 5 * try
        retry if try > 3
      end
    end
  end

  def parse_save_main
    run_id     = keeper.run_id
    list_pages = peon.give_list(subfolder: "#{run_id}_games_ua").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count, othr_pl_count, not_prc_count, other_type_count = [0, 0, 0, 0]
    list_pages.each do |name|
      puts name.green if @debug
      file       = peon.give(file: name, subfolder: "#{run_id}_games_ua")
      parser     = Parser.new(html: file)
      list_games = parser.parse_list_games_ua
      parser_count     += parser.parsed
      othr_pl_count    += parser.other_platform
      not_prc_count    += parser.not_price
      other_type_count += parser.other_type
      binding.pry
      keeper.save_ua_games(list_games)
      @pages += 1
    end
    message = make_message(othr_pl_count, not_prc_count, parser_count, other_type_count)
    notify message if message.present?
  end

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
    notify "Parsed and updated lang info for #{keeper.updated_lang} game(s)."
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
    notify "Parsed and updated description for #{keeper.updated_desc} game(s)."
  end

  def parse_save_desc_ru
    run_id     = keeper.run_id
    list_pages = peon.list(subfolder: "#{run_id}_games_ru").sort_by { |name| name.scan(/\d+/).first.to_i }
    list_pages.each do |name_list_page|
      list_games = peon.list(subfolder: "#{run_id}_games_ru/#{name_list_page}")
      list_games.each do |name|
        puts name.green
        file      = peon.give(file: name, subfolder: "#{run_id}_games_ru/#{name_list_page}")
        parser    = Parser.new(html: file)
        list_info = parser.parse_game_desc
        keeper.save_desc(list_info)
      end
    end
  end

  def make_message(othr_pl_count, not_prc_count, parser_count, other_type_count)
    message = ""
    message << "\nSaved: #{keeper.count[:saved]} games;" unless keeper.count[:saved].zero?
    message << "\nUpdated prices: #{keeper.count[:updated]} games;" unless keeper.count[:updated].zero?
    message << "\nUpdated menuindex: #{keeper.count[:updated_menu_id]} games;" unless keeper.updated_menu_id.zero?
    message << "\nSkipped: #{keeper.skipped} games;" unless keeper.skipped.zero?
    message << "\nNot parsed other platform: #{othr_pl_count} games;" unless othr_pl_count.zero?
    message << "\nNot parsed without or low price: #{not_prc_count} games;" unless not_prc_count.zero?
    message << "\nNot parsed other type: #{other_type_count} games;" unless other_type_count.zero?
    message << "\nParsed: #{@pages} pages, #{parser_count} games." unless parser_count.zero?
    message
  end

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
