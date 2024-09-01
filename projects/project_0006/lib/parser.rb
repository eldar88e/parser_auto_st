require_relative '../models/sony_game_additional'
class Parser < Hamster::Parser
  EXCHANGE_RATE_MIN = 1.5 # До 8000 RS - 1.5р за 1 RS
  EXCHANGE_RATE_MAX = 1.4 # От 8000 RS - 1.4р за 1 RS

  def initialize(**page)
    super
    @html   = Nokogiri::HTML(page[:html])
    @parsed = 0
  end

  attr_reader :parsed

  def parse_games_list
    @html.css('div.game-collection-item').map { |i| i.at('a')['href'] }
  end

  def parse_genre_lang
    dl = @html.at('dl.psw-l-grid')
    return if dl.nil?

    row_data = formit_row_lang(dl)
    formit_genre_lang(row_data)
  end

  def get_last_page
    count_result   = @html.at('div.results').text.match(/\d+/).to_s.to_i
    games_per_page = @html.css('div.game-collection-item').size
    last_page_bad  = count_result / games_per_page
    last_page_f    = count_result / games_per_page.to_f
    last_page_f > last_page_bad ? last_page_bad + 1 : last_page_bad
  end

  def parse_list_games_in
    games      = []
    translator = Hamster::Translator.new
    games_raw  = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game           = { main: {}, additional: {} }
      price_rs_raw   = game_raw.at('span.game-collection-item-price')&.text
      platform       = game_raw.at('.game-collection-item-top-platform').text
      date_raw       = game_raw.at('.game-collection-item-end-date')&.text&.match(/\d{1,2}\s+days?|\d{1,2}\s+months?/)
      prise_discount = game_raw.at('span.game-collection-item-price-discount')&.text
      prise_bonus    = game_raw.at('span.game-collection-item-price-bonus')&.text

      if prise_discount.present?
        game[:additional][:price_tl]     = get_price(prise_discount)
        game[:additional][:price]        = get_price(prise_discount, :ru)
        game[:additional][:old_price_tl] = get_price(price_rs_raw)
        game[:additional][:old_price]    = get_price(price_rs_raw, :ru)
      else
        game[:additional][:price_tl]     = get_price(price_rs_raw)
        game[:additional][:price]        = get_price(price_rs_raw, :ru)
      end

      game[:additional][:old_price]         = nil if game[:additional][:old_price] == game[:additional][:price]
      game[:additional][:price_bonus_tl]    = get_price(prise_bonus)
      game[:additional][:price_bonus]       = get_price(prise_bonus, :ru)
      game[:additional][:discount_end_date] = get_discount_end_date(date_raw)
      game[:main][:pagetitle]               = game_raw.at('.game-collection-item-details-title').text
      game[:additional][:platform]          = platform.gsub(' / ', ', ').gsub(/, PS Vita|, PS3/, '')
      type_game_raw                         = game_raw.at('.game-collection-item-type').text
      game[:additional][:type_game]         = translator.translate_type(type_game_raw)
      game[:additional][:image_link_raw]    = game_raw.at('img.game-collection-item-image')['content']
      data_source_url                       = settings['site'] + game_raw.at('a')['href']
      game[:additional][:data_source_url]   = transliterate data_source_url
      game[:additional][:janr]              = game[:additional][:image_link_raw].split('/')[11]
      game[:additional][:article]           = data_source_url.split('/')[-2]
      game[:main][:alias]                   = make_alias(data_source_url)
      games << game
      @parsed += 1
    end
    games
  end

  private

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

  def formit_genre_lang(info)
    result              = {}
    result[:release]    = info[:release]
    result[:publisher]  = info[:publisher]
    result[:genre]      = form_genres(info[:genres])
    binding.pry if result[:genre].match?(/\A,\s/)
    result[:rus_voice]  = exist_rus?(info)
    result[:rus_screen] = exist_rus?(info, 'screen')
    result
  end

  def exist_rus?(info, params='voice')
    info.any? { |key, value| key.to_s.match?(%r[#{params}]) && value.downcase.match?(/russia/) }
  end

  def form_genres(genre_raw)
    return 'Другое' unless genre_raw.present?

    genre = genre_raw.split(', ').map { |i| i.present? ? i.strip : nil }.compact.uniq.sort.join(', ')
    translate_genre(genre)
  end

  def translate_genre(text)
    text.split(', ').map { |i| Hamster::Translator.new.translate_genre(i) }.join(', ')
  end

  def transliterate(str)
    url = URI.decode_www_form(str)[0][0]
    url.to_slug.transliterate(:russian).to_s
  end

  def make_alias(url)
    url           = transliterate(url) if url.match?(/%/)
    alias_raw     = url.split('/')[-2..-1]
    alias_raw[-1] = alias_raw[-1][0..120]
    alias_raw.reverse.join('-')[0..120]
  end

  def get_price(raw_price, currency=:rs)
    return unless raw_price.present?

    price = raw_price.downcase.gsub('rs', '').gsub(',', '').to_f
    return price if currency == :rs

    exchanged_price = make_exchange_rate(price)
    round_up_price exchanged_price
  end

  def make_exchange_rate(price)
    price * (price < 8000 ? EXCHANGE_RATE_MIN : EXCHANGE_RATE_MAX)
  end

  def round_up_price(price)
    (price / settings['round_price'].to_f).round * settings['round_price']
  end

  def get_discount_end_date(date_raw)
    return unless date_raw

    date_raw  = date_raw.to_s
    day_month = date_raw.match(/days?|months?/)&.to_s.to_sym
    num       = date_raw.to_i
    today     = Date.today
    today + num.send(day_month)
  end
end
