require_relative '../models/sony_game_additional'

class Parser < Hamster::Parser
  MIN_PRICE = 15

  def initialize(**page)
    super
    @parsed     = 0
    @translator = Hamster::Translator.new
    @html       = Nokogiri::HTML(page[:html])
  end

  attr_reader :parsed

  def parse_games_list
    @html.css('div.game-collection-item').map { |i| i.at('a')['href'] }
  end

  def parse_desc_dd
    script = @html.at('body script')
    return unless script

    json_raw = script.text.match(/{.*}/)
    return unless json_raw

    json    = JSON.parse(json_raw.to_s)
    content = json.dig('product', 'product', 'description')
    return unless content

    { content: content.strip.gsub(/<\/?b>/, '').gsub(/\A[<br>]+|[<br>]+\z/, '').strip }
  end

  def parse_lang
    dl = @html.at('dl.psw-l-grid')
    return if dl.nil?

    dt_count = dl.css('dt').size
    info     = {}
    dt_count.times do
      key   = dl.at('dt').remove.text.strip.sub(':', '').gsub(' ', '_').downcase.to_sym
      value = dl.at('dd').remove.text
      next if key == :platform

      info[key] = key == :release ? Date.parse(value) : value
    end

    need_keys = %i[publisher genre release]
    lang      = info.slice!(*need_keys)
    new_lang  = { voice: '', screen_lang: '' }
    lang.each do |k, v|
      new_lang[:voice]       += v if k.to_s.match?(/voice/)
      new_lang[:screen_lang] += v if k.to_s.match?(/screen/)
    end
    info[:rus_voice]  = new_lang[:voice].downcase.match?(/rus/)
    info[:rus_screen] = new_lang[:screen_lang].downcase.match?(/rus/)
    info
  end

  def parse_game_desc
    desc_raw = @html.at('div#game-details-right div.col-xs-12 span[itemprop="description"]')
    return unless desc_raw

    url         = @html.at('link[rel="canonical"]')['href']
    alias_uri   = url.split('/').last
    description = desc_raw.children.to_html.strip.gsub(/<\/?b>/, '').gsub(/\A[<br>]+|[<br>]+\z/, '').strip
    { desc: description, alias: alias_uri }
  end

  def get_last_page
    count_result   = @html.at('div.results').text.match(/\d+/).to_s.to_i
    games_per_page = @html.css('div.game-collection-item').size
    last_page_bad  = count_result / games_per_page
    last_page_f    = count_result / games_per_page.to_f
    last_page_f > last_page_bad ? last_page_bad + 1 : last_page_bad
  end

  def parse_list_games
    games     = []
    games_raw = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game           = { main: {}, additional: {} }
      price_tl_raw   = game_raw.at('span.game-collection-item-price')&.text
      platform       = game_raw.at('.game-collection-item-top-platform').text
      match_date     = %r[\d день|\d+ дня|\d+ дней|\d+ месяца?|\d+ месяцев|\d+ days?|\d+ months?]
      date_raw       = game_raw.at('.game-collection-item-end-date')&.text&.match(match_date)&.to_s
      prise_discount = game_raw.at('span.game-collection-item-price-discount')&.text
      prise_bonus    = game_raw.at('span.game-collection-item-price-bonus')&.text

      if prise_discount && !prise_discount.strip.to_i.zero?
        game[:additional][:price_tl]     = get_price(prise_discount)
        game[:additional][:price]        = get_price(prise_discount, :ru)
        game[:additional][:old_price_tl] = get_price(price_tl_raw)
        game[:additional][:old_price]    = get_price(price_tl_raw, :ru)
      else
        game[:additional][:price_tl]     = get_price(price_tl_raw)
        game[:additional][:price]        = get_price(price_tl_raw, :ru)
        game[:additional][:old_price_tl] = nil
        game[:additional][:old_price]    = nil
      end

      game[:additional][:old_price]         = nil if game[:additional][:old_price] == game[:additional][:price]
      game[:additional][:price_bonus_tl]    = get_price(prise_bonus)
      game[:additional][:price_bonus]       = get_price(prise_bonus, :ru)
      game[:additional][:discount_end_date] = get_discount_end_date(date_raw)

      game[:main][:pagetitle]             = prepare_page_title(game_raw.at('.game-collection-item-details-title').text)
      game[:additional][:platform]        = platform.gsub(' / ', ', ').gsub(/, PS Vita|, PS3/, '')
      type_game_raw                       = game_raw.at('.game-collection-item-type').text
      game[:additional][:type_game]       = @translator.translate_type(type_game_raw)
      game[:additional][:image_link_raw]  = game_raw.at('img.game-collection-item-image')['content']
      game[:additional][:data_source_url] = settings['site'] + game_raw.at('a')['href']
      game[:additional][:janr]            = game[:additional][:image_link_raw].split('/')[11]
      game[:additional][:article]         = game[:additional][:data_source_url].split('/')[-2]
      game[:main][:alias]                 = make_alias(game[:additional][:data_source_url])

      games << game
      @parsed += 1
    end
    games
  end

  private

  def prepare_page_title(page_title_raw)
    page_title_raw.gsub!(/[yY][öÖ][nN][eE][tT][mM][eE][nN][iİ][nN] [Ss][üÜ][rR][üÜ][mM][üÜ]?/, 'режиссерская версия')
    page_title_raw.gsub!(/[Ss][üÜ][rR][üÜ][mM][üÜ]?/, 'edition')
    page_title_raw.gsub!(/[Pp][aA][kK][eE][tT][iİI]?/, 'bundle')
    page_title_raw.gsub!(/[Pp]lay[Ss]tation/, 'PS')
    page_title_raw.gsub!(/[Dd]ijital/, 'digital')
    page_title_raw = replace_turk_small_letters(page_title_raw)
    page_title_raw.gsub('Ü','U').gsub('Ö', 'O').gsub('İ', 'I').gsub('Ç', 'C')
                  .gsub('Ş', 'S').gsub('Ğ', 'G').gsub('™', '').gsub('®', '').gsub(' ve ', ' and ')
  end

  def make_alias(url)
    alias_raw     = url.split('/')[-2..-1]
    alias_raw[-1] = alias_raw[-1][0..120]
    alias_raw     = alias_raw.reverse.join('-')[0..120]
    alias_raw     = URI.decode_www_form(alias_raw)[0][0] if alias_raw.match?(/%/)
    alias_raw.gsub!(/s[uü]r[uü]m[uü]?/, 'edition')
    alias_raw.gsub!(/paketi?/, 'bundle')
    alias_raw.gsub!(/y[oö]netmeni?n?/, 'director')
    alias_raw.gsub!(/-ve-/, '-and-')
    replace_turk_small_letters(alias_raw)
  end

  def replace_turk_small_letters(str)
    str.gsub('ü','u').gsub('ö','o').gsub('ı', 'i').gsub('ğ', 'g').gsub('ç', 'c').gsub('ş','s').gsub('â', 'a')
  end

  def get_price(raw_price, currency=:tr)
    return if raw_price.nil? || raw_price.strip.to_i.zero?

    price = raw_price.strip.gsub(',', '').to_f
    return price if currency == :tr

    exchange_rate = make_exchange_rate(price)
    round_up_price(price * exchange_rate)
  end

  def make_exchange_rate(price)
    #от 1 до 50 лир курс - 10
    #От 51 до 300 лир курс - 5.5
    # от 300 до 800 лир курс 5
    # от 800 до 1600 курс 4.5
    # от 1600 курс 4.3
    if price >= 1 && price < 51
      settings['exchange_rate'] + 4.5
    elsif price >= 51 && price < 300
      settings['exchange_rate']
    elsif price >= 300 && price < 800
      settings['exchange_rate'] - 0.5
    elsif price >= 800 && price < 1600
      settings['exchange_rate'] - 1
    elsif price >= 1600
      settings['exchange_rate'] - 1.2
    end
  end

  def round_up_price(price)
    (price / settings['round_price'].to_f).round * settings['round_price']
  end

  def get_discount_end_date(date_raw)
    return unless date_raw

    day_month     = date_raw.match?(/день|дня|дней|day|days/) ? :days : :months
    num_day_month = date_raw.to_i
    today         = Date.today
    today + num_day_month.send(day_month)
  end
end
