require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  MIN_PRICE = 1 # это примерно 125 на 31.08.2024

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

  def scrape_lang(id)
    url      = @settings[:sony_url] + id
    response = get_response(url)
    return if response&.status == 404

    sleep rand(0.1..0.9)
    response&.body
  end

  def scrape_games_in
    path_in    = settings['path_tr'].sub('tr-store', 'in-store')
    params     = settings['params'].sub('&minPrice=15', "&minPrice=#{MIN_PRICE}")
    first_page = "#{settings['site']}#{path_in}1#{params}"
    last_page  = make_last_page(first_page)
    [*1..last_page].each do |page|
      link = "#{settings['site']}#{path_in}#{page}#{params}"
      puts "Page #{page} of #{last_page}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.2..1.5))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_in")
      @count += 1
    end
  end

  private

  attr_reader :run_id

  def make_last_page(first_page)
    game_list = get_response(first_page).body
    parser    = Parser.new(html: game_list)
    parser.get_last_page
  end

  def get_response(link, try=1)
    headers  = { 'Referer' => @referers.sample, 'Accept-Language' => 'en-US' }
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
