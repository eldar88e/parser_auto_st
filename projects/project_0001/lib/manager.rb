require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/exporter'
require 'net/ftp'
require_relative '../../../concerns/game_modx/manager'

class Manager < Hamster::Harvester
  include GameModx::Manager

  def initialize
    super
    @settings = { touch_update_desc: settings['touch_update_desc'],
                  day_all_lang_scrap: settings['day_all_lang_scrap'],
                  sony_url: settings['ps_game']
                }
    @keeper = Keeper.new(@settings)
    @debug  = commands[:debug]
    @pages  = 0

  end

  def export
    keeper.status = 'exporting'
    exporter      = Exporter.new(keeper)
    domens        = %i[open_ps ps_try reloc ps_store]
    domens.each do |domen|
      csv       = exporter.make_csv(domen)
      file_name = "#{keeper.run_id}_#{domen.to_s}_games.csv.gz"
      peon.put(file: file_name, content: csv)
      #csv_str = peon.give(file: file_name)

      file_path    = "#{@_storehouse_}store/#{file_name}"
      gz_file_data = IO.binread(file_path)
      Hamster.send_file(gz_file_data, file_name)
    end

    notify "Exporting finish!" if @debug
  end

  def download
    peon.move_all_to_trash
    puts 'The Store has been emptied.' if @debug
    peon.throw_trash(3)
    puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping started' if @debug
    scraper = Scraper.new(keeper: keeper)
    scraper.scrape_games_tr
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing started' if @debug
    keeper.status = 'parsing'

    if commands[:lang]
      parse_save_genre_lang
      return
    elsif commands[:desc]
      #parse_save_desc_ru
      parse_save_desc_dd
      return
    end

    parse_save_main

    if keeper.count[:saved] > 0 || (settings['day_all_lang_scrap'].to_i == Date.current.day && Time.current.hour > 12)
      parse_save_genre_lang
    end

    parse_save_genre_lang if keeper.count[:saved] > 0
    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old games" if keeper.count[:deleted] > 0
    cleared_cache = false
    if !keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?
      clear_cache
      cleared_cache = true
    end
    export if !keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:updated_menu_id].zero?
    keeper.finish
    notify '👌 The parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    clear_cache if !cleared_cache && (!keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?)
  end

  private

  def parse_save_main
    run_id       = keeper.run_id
    list_pages   = peon.give_list(subfolder: "#{run_id}_games_tr").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count = 0
    list_pages.each do |name|
      puts name.green if @debug
      file       = peon.give(file: name, subfolder: "#{run_id}_games_tr")
      parser     = Parser.new(html: file)
      list_games = parser.parse_list_games
      parser_count += parser.parsed
      keeper.save_games(list_games)
      @pages += 1
    end
    message = make_message(parser_count)
    notify message if message.present?
  end

  def parse_save_genre_lang
    if settings['day_all_lang_scrap'].to_i == Date.current.day && Time.current.hour > 12
      notify "⚠️ Day of parsing All games without rus lang!"
    end
    run_parse_save_lang
    notify "📌 Updated lang for #{keeper.count[:updated_lang]} game(s)." if keeper.count[:updated_lang] > 0
  end

  def parse_save_desc_dd
    games   = keeper.fetch_game_without_content
    scraper = Scraper.new(keeper: keeper)
    games.each do |game|
      page   = scraper.scrape_desc(game.janr)
      parser = Parser.new(html: page)
      desc   = parser.parse_desc_dd
      next unless desc

      keeper.save_desc_dd(desc, games)
    end
    notify "📌 Added description for #{keeper.count[:updated_desc]} game(s)." if keeper.count[:updated_desc] > 0
  end

  def make_message(parser_count)
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new games;\n" unless keeper.count[:saved].zero?
    message << "✅ Restored: #{keeper.count[:restored]} games;\n" unless keeper.count[:restored].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} games;\n" unless keeper.count[:updated].zero?
    message << "✅ Skipped prices: #{keeper.count[:skipped]} games;\n" unless keeper.count[:skipped].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} games;\n" if keeper.count[:updated_menu_id] > 0
    message << "✅ Parsed: #{@pages} pages, #{parser_count} games." unless parser_count.zero?
    message
  end
end
