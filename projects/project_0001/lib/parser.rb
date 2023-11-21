class Parser < Hamster::Parser
  EXCHANGE_RATE = 5.5
  SITE          = 'https://psdeals.net'

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
  end

  def parse_games_list
    @html.css('div.game-collection-item').map { |i| i.at('a')['href'] }
  end

  def parse_list_info
    #url_raw         = @html.at('link[rel="canonical"]') || @html.at('link[rel="self"]')
    #data_source_url = url_raw['href']
    #data_source_url = SITE + data_source_url unless data_source_url.include?(SITE)
    games           = []
    games_raw       = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game                         = { main: {}, additional: {} }
      game[:main][:pagetitle]      = game_raw.at('.game-collection-item-details-title').text
      game[:additional][:platform] = game_raw.at('.game-collection-item-top-platform').text.gsub(' / ', ', ')
      type_raw                     = game_raw.at('.game-collection-item-type').text
      game[:additional][:type]     = translate_type(type_raw)
      price_tl_raw                 = game_raw.at('.game-collection-item-price')&.text

      if price_tl_raw
        prise_discount = game_raw.at('.game-collection-item-price-bonus')&.text || game_raw.at('.game-collection-item-price-discount')&.text
        if prise_discount
          game[:additional][:price_tl]          = get_price(prise_discount)
          game[:additional][:price]             = get_price(prise_discount, :ru)
          date_raw                              = game_raw.at('.game-collection-item-end-date')&.text
          game[:additional][:discount_end_date] = get_discount_end_date(date_raw)
          game[:additional][:old_price_tl]      = get_price(price_tl_raw)
          game[:additional][:old_price]         = get_price(price_tl_raw, :ru)
        else
          game[:additional][:price_tl] = get_price(price_tl_raw)
          game[:additional][:price]    = get_price(price_tl_raw, :ru)
        end
      end

      game[:additional][:image_link_raw]  = game_raw.at('img.game-collection-item-image')['content']
      game[:additional][:data_source_url] = SITE + game_raw.at('a')['href']
      game[:additional][:article]         = game[:additional][:data_source_url].split('/')[-2]
      games << game
    rescue => e
      puts e
      binding.pry
    end
    games
  end

  private

  def get_price(raw_price, currency=:tr)
    price = raw_price.gsub(',', '').to_f
    return price if currency == :tr

    price * EXCHANGE_RATE
  end

  def get_discount_end_date(date_raw)
    today = Date.today
    binding.pry
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

end
