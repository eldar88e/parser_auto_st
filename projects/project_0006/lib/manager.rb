require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../models/india_setting'
require_relative '../lib/exporter'
require 'net/ftp'
require_relative '../../../concerns/game_modx/manager'

class Manager < Hamster::Harvester
  include GameModx::Manager

  def initialize
    super
    @parse_count = 0
    @debug       = commands[:debug]
    @settings    = IndiaSetting.pluck(:variable, :value).to_h { |key, value| [key.to_sym, value] }
    @keeper      = Keeper.new(@settings)
    @day_all_lang_parsing = @settings[:day_all_lang_scrap].to_i == Date.current.day && Time.current.hour < 12
  end

  def export
    keeper.status = 'exporting'
    exporter      = Exporter.new(keeper)
    domen         = :indiaps
    csv           = exporter.make_csv(domen)
    file_name     = "#{keeper.run_id}_#{domen.to_s}_games.csv.gz"
    peon.put(file: file_name, content: csv)
    file_path    = "#{@_storehouse_}store/#{file_name}"
    gz_file_data = IO.binread(file_path)
    Hamster.send_file(gz_file_data, file_name)
    notify "Exporting finish!" if @debug
  end

  def download
    peon.move_all_to_trash
    puts 'The Store has been emptied.' if @debug
    peon.throw_trash(5)
    puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping PS_IN started' if @debug
    scraper = Scraper.new(keeper: keeper, settings: @settings)
    scraper.scrape_games_in
    notify "Scraping IN finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing PS_IN started' if @debug
    keeper.status = 'parsing'
    return parse_save_desc_lang if commands[:lang]

    parse_save_main
    parse_save_desc_lang if @day_all_lang_parsing || keeper.count[:saved] > 0
    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old #{COUNTRY_FLAG[keeper.class::MADE_IN]} game(s)" if keeper.count[:deleted] > 0

    has_update    = keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0
    cleared_cache = false
    cleared_cache = clear_cache if has_update

    export        if has_update || keeper.count[:updated_menu_id] > 0
    export_google if has_update
    keeper.finish
    notify "👌 Parser #{COUNTRY_FLAG[keeper.class::MADE_IN]} succeeded!"
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
    list_pages   = peon.give_list(subfolder: "#{run_id}_games_in").sort_by { |name| name.scan(/\d+/).first.to_i }
    parser_count = 0
    list_pages.each do |name|
      puts name.green if @debug
      file       = peon.give(file: name, subfolder: "#{run_id}_games_in")
      parser     = Parser.new(html: file)
      list_games = parser.parse_list_games_in
      parser_count += parser.parsed
      keeper.save_in_games(list_games)
      @parse_count += 1
    end
    message = make_message(parser_count)
    notify message if message.present?
  end
end
