module GameModx
  module Manager
    COUNTRY_FLAG = { 'Украина' => '🇺🇦', 'Турция' => '🇹🇷', 'Индия' => '🇮🇳' }

    def export_google
      exporter = ::Exporter.new(keeper)
      msg      = exporter.update_google_sheets
      Hamster.report(message: msg.gsub('games', "#{COUNTRY_FLAG[keeper.class::MADE_IN]} games"))
    end

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

    def parse_save_desc_lang
      notify "⚠️ Day of parsing All #{COUNTRY_FLAG[keeper.class::MADE_IN]} games without rus lang!" if @day_all_lang_parsing
      run_parse_save_lang
      notify "📌 Added language for #{keeper.count[:updated_lang]} #{COUNTRY_FLAG[keeper.class::MADE_IN]} game(s)." if keeper.count[:updated_lang] > 0
      notify "📌 Added description for #{keeper.count[:updated_desc]} #{COUNTRY_FLAG[keeper.class::MADE_IN]} game(s)." if keeper.count[:updated_desc] > 0
    end

    def notify(message, color=:green, method_=:info)
      Hamster.logger.send(method_, message)
      Hamster.report message: message
      puts color.nil? ? message : message.send(color) if @debug
    end

    def make_message(parser_count=nil)
      message = "#{COUNTRY_FLAG[keeper.class::MADE_IN]} #{keeper.class::MADE_IN}\n"
      message << "✅ Saved: #{keeper.count[:saved]} new games;\n" if keeper.count[:saved] > 0
      message << "✅ Restored: #{keeper.count[:restored]} games;\n" if keeper.count[:restored] > 0
      message << "✅ Updated prices: #{keeper.count[:updated]} games;\n" if keeper.count[:updated] > 0
      message << "✅ Updated top: #{keeper.count[:updated_menu_id]} games;\n" if keeper.count[:updated_menu_id] > 0
      last_msg = "✅ Parsed: #{@parse_count} pages, #{parser_count} games."
      message << (parser_count ? last_msg : "✅ Imported: #{@parse_count} games.")
      message
    end
  end
end
