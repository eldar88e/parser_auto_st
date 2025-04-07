require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require 'net/ftp'

class Manager < Hamster::Harvester
  RUN_ID     = 1
  PARENT_ID  = 12 # спецтехника
  ROOT_ALIAS = 'katalog/specztexnika/'.freeze
  MATCH      = {
    '1190097' => 'hitachi', '431769' => 'komatsu', '2369142' => 'hyundai-stekla', 'stekla-bobcat-1' => 'bobcat',
    'stekla-xgma' => 'xgma', 'stekla-sem' => 'sem', 'stekla-liugong' => 'liugon', 'stekla-fiat-hitachi-' => 'fiat-hitachi',
    'stekla-daewoo-' => 'daewoo', 'stekla--mustang' => 'mustang', 'stekla-bucher' => 'bucher-citycat',
    'stekla-hamm-1' => 'hamm', 'stekla-yanmar-' => 'yanmar', 'stekla-dlya-sdlg1' => 'sdlg', 'stekla--dieci' => 'dieci',
    'stekla-bomag' => 'bomag'
  }.freeze

  def initialize
    super
    @debug  = commands[:debug]
    @keeper = Keeper.new(nil)
  end

  def download
    # peon.move_all_to_trash
    # puts 'The Store has been emptied.' if @debug
    # peon.throw_trash(3)
    # puts 'The Trash has been emptied of files older than 10 days.' if @debug
    notify 'Scraping started' if @debug
    scraper = Scraper.new(keeper: nil) # keeper
    scraper.scrape
    notify "Scraping finish! Scraped: #{scraper.count} pages." if @debug
  end

  def store
    brands = peon.give_dirs(subfolder: RUN_ID.to_s)
    notify "Parsing started #{brands.size} brands" if @debug
    titles = json_saver.urls
    # next_brands = true
    brands.each do |brand|
      puts brand.green if @debug

      # next_brands = false if brand == 'stekla_sandvik'
      # next if next_brands

      brand_alias = MATCH[brand.gsub('_', '-')]
      brand_alias ||= brand.gsub('_', '-')
      brand_db = ModxSiteContent.find_by(parent: PARENT_ID, alias: brand_alias)
      if brand_db.nil?
        notify("Brand #{brand} not find!", :red, :error)
        next
      end

      models = peon.give_dirs(subfolder: RUN_ID.to_s + '/' + brand)
      pages  = peon.give_list(subfolder: RUN_ID.to_s + '/' + brand)
      if pages.present?
        uri = "#{ROOT_ALIAS}#{brand_alias}"
        save_pages(pages, brand_db, uri, brand)
        next
      end

      models.each do |model|
        model_alias = model.gsub('_', '-')
        uri         = "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}"
        models_att  = { alias: model_alias, pagetitle: titles[model_alias], uri: uri }
        model_db    = keeper.find_or_create(brand_db, models_att, true)
        pages       = peon.give_list(subfolder: RUN_ID.to_s + '/' + brand + '/' + model)
        if pages.present?
          save_pages(pages, model_db, uri, brand, model)
          next
        end

        types = peon.give_dirs(subfolder: RUN_ID.to_s + '/' + brand + '/' + model)
        types.each do |type|
          type_alias = type.gsub('_', '-')
          uri        = "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}/#{type_alias}"
          type_attr  = { alias: type_alias, pagetitle: titles[type_alias], uri: uri }
          type_db    = keeper.find_or_create(model_db, type_attr)
          pages      = peon.give_list(subfolder: RUN_ID.to_s + '/' + brand + '/' + model + '/' + type)
          save_pages(pages, type_db, uri, brand, model, type)
        end
      end
    end

    notify "Success parsed #{keeper.count[:saved]} products."

    # clear_cache
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    #clear_cache
  end

  private

  attr_accessor :keeper

  def save_pages(pages, page_db, uri, brand, model=nil, type=nil)
    pages.each do |item|
      item_alias = item.gsub('_', '-').sub('.gz', '')
      subfolder  = "#{RUN_ID.to_s}/#{brand}"
      subfolder += "/#{model}" if model
      subfolder += "/#{type}" if type
      body   = peon.give(file: item, subfolder:  subfolder)
      data   = Parser.new(html: body).parse
      data_2 = { alias: item_alias.gsub('.html', ''), uri: uri + "/#{item_alias}" }
      keeper.save_product(page_db, data.merge(data_2))
    end
  end


  def clear_cache(user_env='FTP_LOGIN', pass_env='FTP_PASS')
    ftp_host = ENV.fetch('FTP_HOST')
    ftp_user = ENV.fetch(user_env)
    ftp_pass = ENV.fetch(pass_env)

    Net::FTP.open(ftp_host, ftp_user, ftp_pass) do |ftp|
      %w[/core/cache/context_settings/web /core/cache/resource/web/resources].each do |path|
        ftp.chdir(path)
        delete_files(ftp)
      end
    end
    notify "The cache has been emptied." if @debug
    true
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

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
