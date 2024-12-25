module GameModx
  module Scraper
    attr_reader :count

    def scrape_genre_lang(id)
      url      = @settings[:sony_url] + id
      response = get_response(url)
      return if !response.present? || response.status != 200

      sleep rand(0.3..2.5)
      response.body
    end

    private

    attr_reader :run_id

    def make_last_page(first_page)
      game_list = get_response(first_page).body
      parser    = ::Parser.new(html: game_list)
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
end
