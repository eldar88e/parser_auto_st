require_relative '../models/sony_game_additional'

class Parser < Hamster::Parser
  EXCHANGE_RATE = 5.5
  SITE          = 'https://psdeals.net'

  def initialize(**page)
    super
    @html           = Nokogiri::HTML(page[:html])
    @other_platform = 0
    @not_price      = 0
    @parsed         = 0
  end

  attr_reader :parsed, :other_platform, :not_price

  def parse_games_list
    @html.css('div.game-collection-item').map { |i| i.at('a')['href'] }
  end

  def get_last_page
    count_result   = @html.at('div.results').text.match(/\d+/).to_s.to_i
    games_per_page = @html.css('div.game-collection-item').size
    last_page_bad  = count_result / games_per_page
    last_page_f    = count_result / games_per_page.to_f
    last_page_f > last_page_bad ? last_page_bad + 1 : last_page_bad
  end

  def parse_list_info
    games     = []
    games_raw = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game         = { main: {}, additional: {} }
      price_tl_raw = game_raw.at('span.game-collection-item-price')&.text
      unless price_tl_raw
        @not_price += 0
        next
      end

      platform = game_raw.at('.game-collection-item-top-platform').text
      unless platform.match?(/PS5|PS4/)
        @other_platform += 1
        next
      end

      date_raw       = game_raw.at('.game-collection-item-end-date')&.text&.match(/\d+ months|\d+ days/)
      prise_discount = game_raw.at('span.game-collection-item-price-discount')&.text
      prise_bonus    = game_raw.at('span.game-collection-item-price-bonus')&.text

      if date_raw && (prise_discount || prise_bonus)
        game[:additional][:price_tl]          = get_price(prise_discount)
        game[:additional][:price]             = get_price(prise_discount, :ru)
        game[:additional][:price_bonus_tl]    = get_price(prise_bonus)
        game[:additional][:price_bonus]       = get_price(prise_bonus, :ru)
        game[:additional][:old_price_tl]      = get_price(price_tl_raw)
        game[:additional][:old_price]         = get_price(price_tl_raw, :ru)
        game[:additional][:discount_end_date] = get_discount_end_date(date_raw)
      else
        game[:additional][:price_tl] = get_price(price_tl_raw)
        game[:additional][:price]    = get_price(price_tl_raw, :ru)
      end

      game[:main][:pagetitle]             = game_raw.at('.game-collection-item-details-title').text.gsub(/[S|s]ürümü?/, 'version').gsub(/[P|p]aketi?/, 'bundle')
      game[:additional][:platform]        = platform.gsub(' / ', ', ')
      type_raw                            = game_raw.at('.game-collection-item-type').text
      game[:additional][:type_game]       = translate_type(type_raw)
      game[:additional][:image_link_raw]  = game_raw.at('img.game-collection-item-image')['content']
      game[:additional][:data_source_url] = SITE + game_raw.at('a')['href']
      game[:additional][:janr]            = game[:additional][:image_link_raw].split('/')[11]
      game[:additional][:article]         = game[:additional][:data_source_url].split('/')[-2]
      game[:main][:alias]                 = make_alias(game[:additional][:data_source_url])

      games << game
      @parsed += 1
    rescue => e
      notify e
      binding.pry
    end
    games
  end

  private

  def make_alias(url)
    alias_raw = url.split('/')[-2..-1].reverse.join('-')
    return alias_raw unless alias_raw.match?(/%/)

    alias_raw = URI.decode_www_form(alias_raw)[0][0]
    alias_raw.gsub('sürümü', 'version').gsub('ü','u').gsub('ö','o').gsub('ğ', 'g').gsub('ç', 'c').gsub('ş','s').gsub('ı', 'i')
  end

  def get_price(raw_price, currency=:tr)
    return unless raw_price

    price = raw_price.gsub(',', '').to_f
    return price if currency == :tr

    price * EXCHANGE_RATE
  end

  def get_discount_end_date(date_raw)
    date_raw      = date_raw.to_s
    day_month     = date_raw.match?(/day/) ? :days : :months
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
      'VR Игра'
    else
      type_raw
    end
  end

  def notify(message, color=:green, method_=:info)
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts message.send(color) if @debug
  end
end
