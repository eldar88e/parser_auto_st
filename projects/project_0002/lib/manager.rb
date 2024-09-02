require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../models/parser_setting'
require 'net/ftp'
require_relative '../../../concerns/game_modx/manager'

class Manager < Hamster::Harvester
  include GameModx::Manager

  def initialize
    super
    @debug    = commands[:debug]
    @pages    = 0
    @settings = ParserSetting.pluck(:variable, :value).to_h { |key, value| [key.to_sym, value] }
    @keeper   = Keeper.new(@settings)
  end

  def download
    peon.move_all_to_trash
    puts 'The Store has been emptied.' if @debug
    peon.throw_trash(5)
    puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping PS_UA started' if @debug
    scraper = Scraper.new(keeper: keeper, settings: @settings)
    scraper.scrape_games_ua
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing PS_UA started' if @debug
    keeper.status = 'parsing'

    if commands[:desc]
      parse_save_desc_lang
      return
    end

    parse_save_main

    parse_save_desc_lang if !keeper.count[:saved].zero? || @settings[:day_all_lang_scrap].to_i == Date.current.day

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

  def parse_save_main
    run_id       = keeper.run_id
    list_pages   = peon.give_list(subfolder: "#{run_id}_games_ua").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count = 0
    list_pages.each do |name|
      puts name.green if @debug
      file       = peon.give(file: name, subfolder: "#{run_id}_games_ua")
      parser     = Parser.new(html: file)
      list_games = parser.parse_list_games_ua
      parser_count += parser.parsed
      keeper.save_ua_games(list_games)
      @pages += 1
    end
    message = make_message(parser_count)
    notify message if message.present?
  end

  def parse_save_desc_lang
    if @settings[:day_all_lang_scrap].to_i == Date.current.day && Time.current.hour < 12
      notify "⚠️ Day of parsing All PS_UA games without rus and with empty content!"
    end
    run_parse_save_lang
    notify "📌 Added description for #{keeper.count[:updated_desc]} PS_UA game(s)." unless keeper.count[:updated_desc].zero?
    notify "📌 Added language for #{keeper.count[:updated_lang]} PS_UA game(s)." unless keeper.count[:updated_lang].zero?
  end

  def make_message(parser_count)
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new PS_UA games;\n" unless keeper.count[:saved].zero?
    message << "✅ Restored: #{keeper.count[:restored]} PS_UA games;\n" unless keeper.count[:restored].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} PS_UA games;\n" unless keeper.count[:updated].zero?
    message << "✅ Skipped prices: #{keeper.count[:skipped]} PS_UA games;\n" unless keeper.count[:skipped].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} PS_UA games;\n" unless keeper.count[:updated_menu_id].zero?
    message << "✅ Parsed: #{@pages} pages, #{parser_count} PS_UA games." unless parser_count.zero?
    message
  end
end
