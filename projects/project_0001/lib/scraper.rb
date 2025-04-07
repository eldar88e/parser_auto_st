require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  RUN_ID   = 1
  DOMAIN   = 'komexpress.ru'.freeze
  PREFIX   = '/products/category/'.freeze
  CATEGORY = '/products/category/431754'.freeze

  attr_reader :count

  def initialize(**args)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    @debug    = commands[:debug]
  end

  def scrape
    # existing_brands = peon.give_dirs(subfolder: RUN_ID.to_s)
    brands.each do |brand|
      # next if existing_brands.include? brand.split('/')[-1].gsub('-', '_')
      types_list = process_category(brand, brand)
      types_list.each do |type|
        models_list = process_category(type, brand ,type)
        models_list.each do |model|
          items_list = process_level(model, :product)
          scrape_products(items_list, brand, type, model)
        end
      end
    end
  end

  def brands
    process_level(CATEGORY)
  end

  def scrape_brand(path)
    link = "https://#{DOMAIN}#{path}"
    get_response(link).body
  end

  private

  def process_category(category, brand, type = nil)
    category_list = process_level(category, :check)
    if category_list[:product]
      Hamster.report message: "#{category} without under level" if @debug
      scrape_products(category_list[:result], brand, type)
      []
    else
      category_list[:result]
    end
  end

  def scrape_products(items_list, brand, type = nil, model = nil)
    items_list.each do |item|
      sleep rand(0.3..1.2)
      item_body = get_response(item).body
      subfolder = form_subfolder_path(brand, type, model)
      name      = item.gsub("https://#{DOMAIN}/products/", '').gsub('-', '_')
      peon.put(file: "#{name}.html", content: item_body, subfolder: "#{RUN_ID}/#{subfolder}")
      @count += 1
    end
  end

  def form_subfolder_path(brand, type, model)
    result = [brand.sub(PREFIX, '').gsub('/', '_')]
    result << type.sub(PREFIX, '').gsub('/', '_') if type
    result << model.sub(PREFIX, '').gsub('/', '_') if model
    result.join('/').gsub('-', '_')
  end

  def process_level(path, product=nil)
    link_types     = "https://#{DOMAIN}#{path}"
    types_list_row = get_response(link_types).body
    category_alias = path.gsub(PREFIX, '').gsub(/\/|_/, '-')
    add_alias(types_list_row, category_alias) unless json_saver.urls[category_alias]
    result = Parser.new(html: types_list_row).send( product == :product ? :parse_product_list : :parse_list)
    product == :check ? check_product(types_list_row, result) : result
  end

  def check_product(types_list_row, result)
    return  { result: result, product: false } if result.present?

    result = Parser.new(html: types_list_row).parse_product_list
    { result: result, product: true }
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
