require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/exporter'
require 'net/ftp'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
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
    scraper = Scraper.new(keeper)
    scraper.scrape_games_tr
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug

    if commands[:ru]
      scraper_ru = Scraper.new(keeper)
      scraper_ru.scrape_games_ru
      notify "Scraping finish!\nScraped: #{scraper_ru.count} pages." if @debug
    end
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

    if !keeper.saved.zero? || (settings['day_lang_all_scrap'].to_i == Date.current.day && Time.current.hour > 12)
      parse_save_lang
    end

    parse_save_desc_dd unless keeper.saved.zero?
    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.deleted} old games" if keeper.deleted > 0
    cleared_cache = false
    if !keeper.saved.zero? || !keeper.updated.zero? || !keeper.deleted.zero?
      clear_cache
      cleared_cache = true
    end
    export if !keeper.saved.zero? || !keeper.updated.zero? || !keeper.updated_menu_id.zero?
    keeper.finish
    notify '👌 The parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    clear_cache if !cleared_cache && (!keeper.saved.zero? || !keeper.updated.zero? || !keeper.deleted.zero?)
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

  def parse_save_lang
    if settings['day_lang_all_scrap'].to_i == Date.current.day && Time.current.hour > 12
      notify "⚠️ Day of parsing All games without rus lang!"
    end
    ps_additions = keeper.get_without_rus
    scraper      = Scraper.new(keeper)
    ps_additions.each_with_index do |addition, idx|
      puts "#{idx} || #{addition.janr}".green if @debug
      page   = scraper.scrape_lang(addition.janr)
      parser = Parser.new(html: page)
      lang   = parser.parse_lang
      next if lang.nil?

      keeper.save_lang_info(lang, addition)
    end
    notify "📌 Updated lang for #{keeper.updated_lang} game(s)." unless keeper.updated_lang.zero?
  end

  def parse_save_desc_dd
    games   = keeper.get_ps_ids_without_desc
    scraper = Scraper.new(keeper)
    games.each do |game|
      page   = scraper.scrape_desc(game.janr)
      parser = Parser.new(html: page)
      desc   = parser.parse_desc_dd
      next unless desc

      keeper.save_desc_dd(desc, games)
    end
    notify "📌 Added description for #{keeper.updated_desc} game(s)." unless keeper.updated_desc.zero?
  end

  def parse_save_desc_ru
    run_id     = keeper.run_id
    list_pages = peon.list(subfolder: "#{run_id}_games_ru").sort_by { |name| name.scan(/\d+/).first.to_i }
    list_pages.each do |name_list_page|
      list_games = peon.list(subfolder: "#{run_id}_games_ru/#{name_list_page}")
      list_games.each do |name|
        puts name.green if @debug
        file      = peon.give(file: name, subfolder: "#{run_id}_games_ru/#{name_list_page}")
        parser    = Parser.new(html: file)
        list_info = parser.parse_game_desc
        next unless list_info

        keeper.save_desc(list_info)
      end
    end
  end

  def make_message(parser_count)
    message = ""
    message << "✅ Saved: #{keeper.saved} new games;\n" unless keeper.saved.zero?
    message << "✅ Restored: #{keeper.restored} games;\n" unless keeper.restored.zero?
    message << "✅ Updated prices: #{keeper.updated} games;\n" unless keeper.updated.zero?
    message << "✅ Skipped prices: #{keeper.skipped} games;\n" unless keeper.skipped.zero?
    message << "✅ Updated menuindex: #{keeper.updated_menu_id} games;\n" unless keeper.updated_menu_id.zero?
    message << "✅ Parsed: #{@pages} pages, #{parser_count} games." unless parser_count.zero?
    message
  end

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
