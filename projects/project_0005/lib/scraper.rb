require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize(**args)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    @keeper   = args[:keeper]
    @settings = args[:settings]
    @debug    = commands[:debug]
    @run_id   = @keeper.run_id
  end

  attr_reader :count

  def scrape
    main_path         = @settings[:main_path]
    subcategories_one = get_response(main_path).body
    @html             = Nokogiri::HTML(subcategories_one)
    subcat_list_one   = @html.css('ul.ut2-subcategories li a').map { |i| i['href'] }
    subcat_list_one.each do |subcategori|
      next if subcategori.match?(/pitomcam/)

      subcategori_folder = subcategori.split('/')[-1]
      subcategories_two  = get_response(subcategori).body
      @html              = Nokogiri::HTML(subcategories_two)
      subcat_list_two    = @html.css('ul.ut2-subcategories li a').map { |i| i['href'] }
      subcat_list_two.each do |link|
        sub_sub_folder = link.split('/')[-1]
        page = 1
        loop do
          link_page = link + "page-#{page}/"
          response  = get_response(link_page)
          break if response.status == 404

          subcategories_three = response.body
          @html               = Nokogiri::HTML(subcategories_three)
          products = @html.css('div#categories_view_pagination_contents form div.ut2-gl__image > a').map { |i| i['href'] }
          products.each do |product|
            content_product = get_response(product).body
            name      = product.split('/')[-1].gsub(/-/, '_') + '.html'
            subfolder = "#{run_id}/#{subcategori_folder}/#{sub_sub_folder}".gsub(/-/, '_')
            puts "#{run_id}/#{subcategori_folder}/#{sub_sub_folder}/#{name}".green if @debug
            peon.put(file: name, content: content_product, subfolder: subfolder)
            @count += 1
            sleep rand(0.1..0.7)
          end
          page += 1
        end
      end
    end
  end

  private

  attr_reader :run_id

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
