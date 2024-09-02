module GameModx
  module Manager

    private

    attr_reader :keeper

    def run_parse_save_lang
      sony_games = keeper.fetch_game_without_rus
      scraper    = ::Scraper.new(keeper: keeper, settings: @settings)
      sony_games.each_with_index do |game, idx|
        puts "#{idx} || #{game.janr}".green if @debug
        page = scraper.scrape_genre_lang(game.janr)
        next unless page

        parser     = ::Parser.new(html: page)
        genre_lang = parser.parse_genre_lang
        keeper.save_lang(genre_lang, game) if genre_lang
      end
    end

    def clear_cache
      ftp_host = ENV.fetch('FTP_HOST')
      ftp_user = ENV.fetch('FTP_LOGIN')
      ftp_pass = ENV.fetch('FTP_PASS')

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

    def notify(message, color=:green, method_=:info)
      Hamster.logger.send(method_, message)
      Hamster.report message: message
      puts color.nil? ? message : message.send(color) if @debug
    end
  end
end
