require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  DOMAIN = 'komexpress.ru'.freeze
  RUN_ID = 1
  PREFIX = '/products/category/'
  BRANDS = { 'stekla_jcb': 'jcb' }

  attr_reader :count

  def initialize(**args)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    # @keeper   = args[:keeper]
    @debug    = commands[:debug]
    # @run_id   = @keeper.run_id
  end

  def scrape
    first_path  = '/products/category/431754'
    brands_list = process_level(first_path)
    brands_list.each do |brand|
      types_list = process_level(brand)
      types_list.each do |type|
        models_list = process_level(type)
        models_list.each do |model|
          items_list = process_level(model, true)
          items_list.each do |item|
            sleep rand(0.7..2.3)
            item_body = get_response(item).body
            subfolder = form_subfolder_path(brand, type, model)
            name      = item.gsub("https://#{DOMAIN}/products/", '').gsub('-', '_')
            peon.put(file: "#{name}.html", content: item_body, subfolder: "#{RUN_ID}/#{subfolder}")
            @count += 1
          rescue => e
            puts '=' * 80
            puts e.message
            puts '*' * 80
            binding.pry
          end
        end
      end
    end
  end

  def form_subfolder_path(brand, type, model)
    (brand.gsub(PREFIX, '').gsub('/', '_') + '/' + type.gsub(PREFIX, '').gsub('/', '_') +
      '/' + model.gsub(PREFIX, '').gsub('/', '_')).gsub('-', '_')
  end

  def process_level(path, product=nil)
    link_types     = "https://#{DOMAIN}#{path}"
    types_list_row = get_response(link_types).body
    category_alias = path.gsub(PREFIX, '').gsub(/\/|_/, '-')
    add_alias(types_list_row, category_alias) unless json_saver.urls[category_alias]
    Parser.new(html: types_list_row).send( product ? :parse_product_list : :parse_list)
  end

  def add_alias(types_list_row, category_alias)
    title = Parser.new(html: types_list_row).parse_title
    json_saver.add_url(category_alias, title)
  end

  def get_response(link, try=1)
    headers = { 'Referer' => @referers.sample, 'Accept-Language' => 'en-US,en;q=0.9,ru-RU;q=0.8,ru;q=0.7' }
    response = connect_to(link, ssl_verify: false, headers: headers)
    raise 'Error receiving response from server' unless response.present?
    response
  rescue => e
    try += 1

    if try < 4
      Hamster.logger.error "#{e.message} || #{e.class} || #{link} || try: #{try}"
      sleep 5 * try
      retry
    end

    Hamster.logger.error "#{e.message} || #{e.class} || #{link} || try: #{try}"
    Hamster.report message: "#{e.message} || #{e.class} || #{link} || try: #{try}"
  end
end
