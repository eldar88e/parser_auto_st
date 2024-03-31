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
    notify 'Scraping for Eczane has begun' if @debug
    scraper = Scraper.new(keeper)
    scraper.scrape
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    notify 'Parsing started' if @debug
    keeper.status = 'parsing'

    parse_save_main

    #keeper.delete_not_touched

    cleared_cache = false
    if !keeper.count[:saved].zero? || !keeper.count[:updated].zero? #|| !keeper.count[:deleted].zero?
      clear_cache
      cleared_cache = true
    end

    #keeper.finish
    notify make_message
    notify '👌 The Eczane parser succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    clear_cache if !cleared_cache && (!keeper.count[:saved].zero? || !keeper.count[:updated].zero?) #|| !keeper.count[:deleted].zero?)
  end

  private

  attr_reader :keeper

  def clear_cache
    ftp_host = ENV.fetch('FTP_HOST')
    ftp_user = ENV.fetch('FTP_LOGIN_ECZANE')
    ftp_pass = ENV.fetch('FTP_PASS_ECZANE')

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
    run_id          = keeper.run_id
    list_categories = peon.list(subfolder: "#{run_id}")
    list_categories.each do |cat_name|
      path = "#{run_id}/#{cat_name}"
      list_sub_categories = peon.list(subfolder: path)
      list_sub_categories.each do |sub_name|
        list_name = peon.give_list(subfolder: path + "/#{sub_name}")
        puts "run_id_#{run_id}/#{cat_name}/#{sub_name}".green if @debug
        list_name.each do |name|
          file       = peon.give(file: name, subfolder: path + "/#{sub_name}")
          parser     = Parser.new(html: file)
          supplement = parser.parse_supplement

          keeper.save_supplement(supplement)
          @pages += 1
        end
      end
    end
    notify "Для более 10 товаров не могут быть сохранены. \
    Вот несколько из последних:\n#{keeper.no_parent.last(5).join(', ')}" if keeper.no_parent.size > 10
  end

  def make_message
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new products;\n" unless keeper.count[:saved].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} products;\n" unless keeper.count[:updated].zero?
    message << "✅ Skipped prices: #{keeper.count[:skipped]} products;\n" unless keeper.count[:skipped].zero?
    message << "✅ Updated content: #{keeper.count[:content_updated]} products;\n" unless keeper.count[:content_updated].zero?
    message << "✅ Parsed: #{@pages} products." unless @pages.zero?
    message
  end

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
