require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require 'net/ftp'

class Manager < Hamster::Harvester
  RUN_ID = 1
  ROOT_ID = 12 # спецтехника
  T_SUB_CATEGORY_ID = 17
  T_CATEGORY_ID = 14
  T_PRODUCT_ID = 13
  ROOT_ALIAS = 'katalog/specztexnika/'
  MATCH = { 'stekla_jcb' => 'jcb', 'john-deere-steklo' => 'stekla_john_deere'  }.freeze
  USER_ID = 6

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
    ['stekla_jcb'].each do |brand| # TODO: Убрать HARD CODE !!!
      brand_alias = MATCH[brand]&.gsub('_', '-')
      raise StandardError, "Unknown brand: #{brand}" unless brand_alias

      binding.pry


      brand_db = ModxSiteContent.find_by(parent: 12, alias: brand_alias)
      models   = peon.give_dirs(subfolder: RUN_ID.to_s + '/' + brand)
      models.each do |model|
        model_alias = model.gsub('_', '-')
        model_db = ModxSiteContent.find_by(parent: brand_db.id, alias: model_alias)
        model_db = ModxSiteContent.create(
          parent: brand_db.id, alias: model_alias, pagetitle: titles[model_alias], longtitle: titles[model_alias], published: 1,
          publishedon: Time.current.to_i, publishedby: USER_ID, createdby: USER_ID, createdon: Time.current.to_i,
          uri: "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}", isfolder: 1, template: T_SUB_CATEGORY_ID) unless model_db
        types = peon.give_dirs(subfolder: RUN_ID.to_s + '/' + brand + '/' + model)
        types.each do |type|
          type_alias = type.gsub('_', '-')
          type_db = ModxSiteContent.find_or_initialize_by(parent: model_db.id, alias: type_alias)
          type_db.update!(
            parent: model_db.id, alias: type_alias, pagetitle: titles[type_alias], longtitle: titles[type_alias],
            published: 1, publishedon: Time.current.to_i, publishedby: USER_ID, createdby: USER_ID,
            createdon: Time.current.to_i, uri: "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}/#{type_alias}", isfolder: 1,
            template: T_CATEGORY_ID) unless type_db
          items = peon.give_list(subfolder: RUN_ID.to_s + '/' + brand + '/' + model + '/' + type)
          items.each do |item|
            item_alias = item.gsub('_', '-').sub('.gz', '')
            body = peon.give(file: item, subfolder: RUN_ID.to_s + '/' + brand + '/' + model + '/' + type)
            data = Parser.new(html: body).parse
            data_2 = {
              parent: type_db.id, alias: item_alias.gsub('.html', ''), published: 1, publishedon: Time.current.to_i,
              publishedby: USER_ID, createdby: USER_ID, createdon: Time.current.to_i,
              uri: "#{ROOT_ALIAS}#{brand_alias}/#{model_alias}/#{type_alias}/#{item_alias}", template: T_PRODUCT_ID
            }
            keeper.save_product data.merge(data_2)
          rescue StandardError => e
            puts e
            binding.pry
          end
          puts keeper.count[:saved].to_s.green
        end
        binding.pry
      end
    end

    # clear_cache
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug     = true
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
