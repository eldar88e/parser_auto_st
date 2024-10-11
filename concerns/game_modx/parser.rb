module GameModx
  module Parser
    def get_last_page
      count_result   = @html.at('div.results').text.match(/\d+/).to_s.to_i
      games_per_page = @html.css('div.game-collection-item').size
      last_page_bad  = count_result / games_per_page
      last_page_f    = count_result / games_per_page.to_f
      last_page_f > last_page_bad ? last_page_bad + 1 : last_page_bad
    end

    def parse_genre_lang
      dl = @html.at('dl.psw-l-grid')
      return unless dl.present?

      row_data = formit_row_lang(dl)
      formit_lang(row_data)
    end

    private

    def formit_lang(info)
      result              = {}
      result[:release]    = info[:release]
      result[:publisher]  = info[:publisher]
      result[:genre]      = form_genres(info[:genres])
      result[:rus_voice]  = exist_rus?(info)
      result[:rus_screen] = exist_rus?(info, 'screen')
      result
    end

    def form_genres(genre_raw)
      return 'Другое' unless genre_raw.present?

      genre = genre_raw.split(', ').map(&:strip).uniq.sort.join(', ')
      translate_genre(genre)
    end

    def exist_rus?(info, params='voice')
      info.any? { |key, value| key.to_s.match?(%r[#{params}]) && value.downcase.match?(/russia/) }
    end

    def round_up_price(price)
      (price / settings['round_price'].to_f).round * settings['round_price']
    end

    def transliterate(str)
      url = URI.decode_www_form(str)[0][0]
      url.to_slug.transliterate(:russian).to_s
    end

    def formit_row_lang(chunk)
      dt_count = chunk.css('dt').size
      info     = {}
      dt_count.times do
        key       = chunk.at('dt').remove.text.strip.sub(':', '').gsub(' ', '_').downcase.to_sym
        value     = chunk.at('dd').remove.text
        info[key] = key == :release ? Date.parse(value) : value
      end
      info
    end

    def make_alias(url)
      url           = transliterate(url) if url.match?(/%/)
      alias_raw     = url.split('/')[-2..-1]
      alias_raw[-1] = alias_raw[-1][0..120]
      alias_raw.reverse.join('-')[0..120]
    end

    def get_discount_end_date(date_raw)
      return unless date_raw.present?

      day_month = date_raw.match?(/день|дня|дней|day|days/) ? :days : :months
      num       = date_raw.to_i
      today     = Date.today
      today + num.send(day_month)
    end

    def translate_genre(text)
      text.split(', ').map { |i| @translator.translate_genre(i) }.sort.join(', ')
    end

    def get_price(raw_price, currency=nil)
      return unless raw_price.present?

      price = raw_price.sub(/\.0+/, '').scan(/\d/).join.to_f
      return price if currency.nil?

      exchanged_price = make_exchange_rate(price)
      round_up_price exchanged_price
    end
  end
end
