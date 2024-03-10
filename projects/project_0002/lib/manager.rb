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
    peon.move_all_to_trash
    puts 'The Store has been emptied.' if @debug
    peon.throw_trash(5)
    puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping started' if @debug
    scraper = Scraper.new(keeper)
    scraper.scrape_games_ua
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing started' if @debug
    keeper.status = 'parsing'

    if commands[:desc]
      parse_save_desc_lang_dd
      return
    end

    parse_save_main

    parse_save_desc_lang_dd unless keeper.count[:saved].zero?

    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old PS_UA games" if keeper.count[:deleted] > 0

    cleared_cache = false
    if !keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?
      clear_cache
      cleared_cache = true
    end

    keeper.finish
    notify '👌 The PS_UA parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    clear_cache if !cleared_cache && (!keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?)
  end

  private

  attr_reader :keeper

  def clear_cache
    ftp_host = ENV.fetch('FTP_HOST')
    ftp_user = ENV.fetch('FTP_LOGIN_UA')
    ftp_pass = ENV.fetch('FTP_PASS_UA')

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
      keeper.save_ua_games(list_games)
      @pages += 1
    end
    message = make_message(othr_pl_count, not_prc_count, parser_count, other_type_count)
    notify message if message.present?
  end

  def parse_save_desc_lang_dd
    additional = keeper.get_ps_ids_without_desc_ua
    scraper    = Scraper.new(keeper)
    additional.each do |model|
      page = scraper.scrape_desc(model.janr)
      next unless page

      parser = Parser.new(html: page)
      desc   = parser.parse_desc_dd
      keeper.save_desc_lang_dd(desc, model)
    end
    notify "📌 Added description for #{keeper.count[:updated_desc]} PS_UA game(s)."
    notify "📌 Added language for #{keeper.count[:updated_lang]} PS_UA game(s)."
  end

  def make_message(othr_pl_count, not_prc_count, parser_count, other_type_count)
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new PS_UA games;\n" unless keeper.count[:saved].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} PS_UA games;\n" unless keeper.count[:updated].zero?
    message << "✅ Skipped prices: #{keeper.count[:skipped]} PS_UA games;\n" unless keeper.count[:skipped].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} PS_UA games;\n" unless keeper.count[:updated_menu_id].zero?
    message << "✅ Not parsed other platform: #{othr_pl_count} PS_UA games;\n" unless othr_pl_count.zero?
    message << "✅ Not parsed without or low price: #{not_prc_count} PS_UA games;\n" unless not_prc_count.zero?
    message << "✅ Not parsed other type: #{other_type_count} PS_UA games;\n" unless other_type_count.zero?
    message << "✅ Parsed: #{@pages} pages, #{parser_count} PS_UA games." unless parser_count.zero?
    message
  end

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
