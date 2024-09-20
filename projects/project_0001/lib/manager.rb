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
    @debug    = commands[:debug]
    @settings = { touch_update_desc: settings['touch_update_desc'],
                  day_all_lang_scrap: settings['day_all_lang_scrap'],
                  sony_url: settings['ps_game']
                }
    @keeper      = Keeper.new(@settings)
    @parse_count = 0
    @day_all_lang_parsing = settings['day_all_lang_scrap'].to_i == Date.current.day && Time.current.hour < 12
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
    return parse_save_desc_lang if commands[:lang]
    return parse_save_desc_dd if commands[:desc]

    parse_save_main
    if keeper.count[:saved] > 0 || @day_all_lang_parsing
      parse_save_desc_lang
      parse_save_desc_dd
    end
    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old games" if keeper.count[:deleted] > 0

    has_update    = keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0
    cleared_cache = false
    cleared_cache = clear_cache if has_update

    export if has_update || !keeper.count[:updated_menu_id].zero?
    keeper.finish
    notify '👌 The parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug     = true
    has_update = keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0
    clear_cache if !cleared_cache && has_update
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
      @parse_count += 1
    end
    message = make_message(parser_count)
    notify message if message.present?
  end

  def parse_save_desc_dd
    notify "⚠️ Day of parsing All games without desc!" if @day_all_lang_parsing
    games   = keeper.fetch_game_without_content
    scraper = Scraper.new(keeper: keeper)
    games.each do |game|
      page   = scraper.scrape_desc(game.janr)
      parser = Parser.new(html: page)
      desc   = parser.parse_desc_dd
      next unless desc

      keeper.save_desc(desc, game.sony_game)
    end
    notify "📌 Added description for #{keeper.count[:updated_desc]} #{Keeper::MADE_IN} game(s)." if keeper.count[:updated_desc] > 0
  end
end
