require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require 'net/ftp'

class Manager < Hamster::Harvester
  RUN_ID     = 1
  PARENT_ID  = 12 # спецтехника
  ROOT_ALIAS = 'katalog/specztexnika/'.freeze
  MATCH      = {
    'stekla-jcb' => 'jcb', 'john-deere-steklo' => 'stekla-john-deere', '1190097' => 'hitachi',
    'stekla-caterpillar' => 'caterpillar-steklo', '431769' => 'komatsu', '2369142' => 'hyundai-stekla',
    'stekla-bobcat-1' => 'bobcat', 'stekla-volvo' => 'volvo-steklo', 'stekla-terex' => 'terex',
    'stekla-new-holland' => 'new.holland', 'stekla-john-deere' => 'john-deere-steklo', 'stekla-case' => 'case-stekla'
  }.freeze

  def initialize
    super
    @debug       = commands[:debug]
    @keeper      = Keeper.new(nil)
    @parse_count = 0
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
    # notify 'Parsing started' if @debug
    # keeper.status = 'parsing'
    brands = peon.give_dirs(subfolder: RUN_ID.to_s)
    titles = json_saver.urls
    brands.each do |brand|
      puts brand.green if @debug
      brand_alias = MATCH[brand.gsub('_', '-')]
      # notify("Brand #{brand} not matched!", :red, :warn) if brand_alias.nil? && @debug

      brand_alias ||= brand.gsub('_', '-')
      brand_db    = ModxSiteContent.find_by(parent: PARENT_ID, alias: brand_alias)
      if brand_db.nil?
        notify("Brand #{brand} not find!", :red, :error)
        next
      end

      models   = peon.give_dirs(subfolder: RUN_ID.to_s + '/' + brand)
      models.each do |model|
        model_alias = model.gsub('_', '-')
        models_att  = { alias: model_alias, pagetitle: titles[model_alias],
                        uri: "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}" }
        model_db = keeper.find_or_create(brand_db, models_att, true)
        types    = peon.give_dirs(subfolder: RUN_ID.to_s + '/' + brand + '/' + model)
        types.each do |type|
          type_alias = type.gsub('_', '-')
          type_attr  = { alias: type_alias, pagetitle: titles[type_alias],
                         uri: "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}/#{type_alias}" }
          type_db = keeper.find_or_create(model_db, type_attr)
          items   = peon.give_list(subfolder: RUN_ID.to_s + '/' + brand + '/' + model + '/' + type)
          items.each do |item|
            item_alias = item.gsub('_', '-').sub('.gz', '')
            body       = peon.give(file: item, subfolder: RUN_ID.to_s + '/' + brand + '/' + model + '/' + type)
            data       = Parser.new(html: body).parse
            data_2     = { alias: item_alias.gsub('.html', ''),
                           uri: "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}/#{type_alias}/#{item_alias}" }
            keeper.save_product(type_db, data.merge(data_2))
          end
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
