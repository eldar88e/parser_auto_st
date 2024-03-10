require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize(keeper)
    super
    @referers = YAML.load_file('referer.yml')['referer']
    @count    = 0
    @keeper   = keeper
    @debug    = commands[:debug]
    @run_id   = @keeper.run_id
  end

  attr_reader :count

  def scrape_desc(id)
    url = settings['dd_game'] + id
    response = get_response(url)
    sleep rand(0.5..1.9)
    return if response&.status == 404

    response.body
  end

  def scrape_games_ua
    path_ua = settings['path_tr'].sub('tr-store', 'ua-store')
    first_page = "#{settings['site']}#{path_ua}1#{settings['params']}"
    last_page  = make_last_page(first_page)
    [*1..last_page].each do |page|
      link = "#{settings['site']}#{path_ua}#{page}#{settings['params']}"
      puts "Page #{page} of #{last_page}".green if @debug
      game_list = get_response(link).body
      sleep(rand(0.2..1.5))
      peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_ua")
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
    headers = { 'Referer' => @referers.sample, 'Accept-Language' => 'ua-UA' }
    response = connect_to(link, ssl_verify: false, headers: headers)
    raise 'Error receiving response from server' unless response.present?
    response
  rescue => e
    try += 1

    if try < 4
      Hamster.logger.error "#{e.message} || #{e.class} || #{link} || try: #{try}"
      Hamster.report message: "#{e.message} || #{e.class} || #{link} || try: #{try}"
      sleep 5 * try
      retry
    end

    Hamster.logger.error "#{e.message} || #{e.class} || #{link} || try: #{try}"
  end
end
