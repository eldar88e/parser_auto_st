require_relative '../models/sony_game_additional'

class Parser < Hamster::Parser
  MIN_PRICE     = 15
  EXCHANGE_RATE = 4

  def initialize(**page)
    super
    @html           = Nokogiri::HTML(page[:html])
    @other_platform = 0
    @other_type     = 0
    @not_price      = 0
    @parsed         = 0
  end

  attr_reader :parsed, :other_platform, :not_price, :other_type

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
    rescue => e
      notify e.message
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

  def parse_list_games_ua
    games     = []
    games_raw = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game         = { main: {}, additional: {} }
      price_tl_raw = game_raw.at('span.game-collection-item-price')&.text
      if price_tl_raw.nil? || price_tl_raw.to_i.zero?
        @not_price += 1
        next
      end

      platform = game_raw.at('.game-collection-item-top-platform').text
      unless platform.downcase.match?(/ps5|ps4/)
        @other_platform += 1
        next
      end

      match_date     = %r[\d день|\d+ дня|\d+ дней|\d+ месяца?|\d+ месяцев|\d+ days?|\d+ months?]
      date_raw       = game_raw.at('.game-collection-item-end-date')&.text&.match(match_date)
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

      if game[:additional][:price_tl] < MIN_PRICE
        @not_price += 1
        next
      end

      game[:main][:pagetitle]       = game_raw.at('.game-collection-item-details-title').text
      game[:additional][:platform]  = platform.gsub(' / ', ', ')
      type_game_raw                 = game_raw.at('.game-collection-item-type').text
      game[:additional][:type_game] = translate_type(type_game_raw)

      unless ['Игра', 'Комплект', 'VR игра', 'PSN игра', 'Контент'].include?(game[:additional][:type_game])
        @other_type += 1
        next
      end

      game[:additional][:image_link_raw]  = game_raw.at('img.game-collection-item-image')['content']
      data_source_url                     = settings['site'] + game_raw.at('a')['href']
      game[:additional][:data_source_url] = transliterate data_source_url
      game[:additional][:janr]            = game[:additional][:image_link_raw].split('/')[11]
      game[:additional][:article]         = data_source_url.split('/')[-2]
      game[:main][:alias]                 = make_alias(data_source_url)

      games << game
      @parsed += 1
    end
    games
  end

  private

  def make_alias(url)
    alias_raw     = url.split('/')[-2..-1]
    alias_raw[-1] = alias_raw[-1][0..120]
    alias_raw     = alias_raw.reverse.join('-')[0..120]
    transliterate alias_raw
  end

  def transliterate(str)
    return str unless str.match?(/%/)

    url = URI.decode_www_form(str)[0][0]
    url.to_slug.transliterate(:russian).to_s
  end

  def get_price(raw_price, currency=:ua)
    return if raw_price.nil? || raw_price.strip.to_i.zero?

    price = raw_price.strip.gsub(',', '').to_f
    return price if currency == :ua

    round_up_price(price * EXCHANGE_RATE)
  end

  def round_up_price(price)
    (price / settings['round_price'].to_f).round * settings['round_price']
  end

  def get_discount_end_date(date_raw)
    return unless date_raw

    date_raw      = date_raw.to_s
    day_month     = date_raw.match?(/день|дня|дней|day|days/) ? :days : :months
    num_day_month = date_raw.to_i
    today         = Date.today
    today + num_day_month.send(day_month)
  end

  def translate_type(type_raw)
    case type_raw
    when 'Full Game'
      'Игра'
    when 'Bundle'
      'Комплект'
    when 'VR Game'
      'VR игра'
    when 'PSN Game'
      'PSN игра'
    when 'Game Content'
      'Контент'
    else
      type_raw
    end
  end

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
