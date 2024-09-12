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
    @day_all_lang_parsing = @settings[:day_all_lang_scrap].to_i == Date.current.day && Time.current.hour < 12
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
    return parse_save_desc_lang if commands[:desc] || commands[:lang]

    parse_save_main
    parse_save_desc_lang if @day_all_lang_parsing || keeper.count[:saved] > 0
    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old PS_UA game(s)" if keeper.count[:deleted] > 0

    has_update    = keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0
    cleared_cache = false
    cleared_cache = clear_cache if has_update

    keeper.finish
    notify '👌 The PS_UA parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug     = true
    has_update = keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0
    clear_cache if !cleared_cache && has_update
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
    true
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
    notify "⚠️ Day of parsing All PS_UA games without rus lang and with empty content!" if @day_all_lang_parsing
    run_parse_save_lang
    notify "📌 Added description for #{keeper.count[:updated_desc]} PS_UA game(s)." if keeper.count[:updated_desc] > 0
    notify "📌 Added language for #{keeper.count[:updated_lang]} PS_UA game(s)." if keeper.count[:updated_lang] > 0
  end

  def make_message(parser_count)
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new PS_UA games;\n" unless keeper.count[:saved].zero?
    message << "✅ Restored: #{keeper.count[:restored]} PS_UA games;\n" unless keeper.count[:restored].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} PS_UA games;\n" unless keeper.count[:updated].zero?
    message << "✅ Skipped prices: #{keeper.count[:skipped]} PS_UA games;\n" unless keeper.count[:skipped].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} PS_UA games;\n" if keeper.count[:updated_menu_id] > 0
    message << "✅ Parsed: #{@pages} pages, #{parser_count} PS_UA games." unless parser_count.zero?
    message
  end
end
