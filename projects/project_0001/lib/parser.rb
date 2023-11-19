class Parser < Hamster::Parser
  COURSE = 5.5
  SITE = 'https://psdeals.net'

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
  end

  def parse_games_list
    @html.css('div.game-collection-item').map { |i| i.at('a')['href'] }
  end

  def parse_list_info
    url_raw         = @html.at('link[rel="canonical"]') || @html.at('link[rel="self"]')
    data_source_url = url_raw['href']
    data_source_url = SITE + data_source_url unless data_source_url.include?(SITE)
    games           = []
    games_raw       = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game = {}
      game[:name]     = game_raw.at('.game-collection-item-details-title').text
      game[:platform] = game_raw.at('.game-collection-item-top-platform').text.gsub(' / ', ', ')
      type_raw = game_raw.at('.game-collection-item-type').text
      game[:type]     = translate_type(type_raw)
      game[:prise_tl] = game_raw.at('.game-collection-item-price')&.text
      game[:prise]    =  game[:prise_tl].gsub(',', '').to_f * COURSE if game[:prise_tl]
      game[:prise_discount_tl] =
        game_raw.at('.game-collection-item-price-bonus')&.text || game_raw.at('.game-collection-item-price-discount')&.text
      if game[:prise_discount_tl]
        game[:prise_discount]   = game[:prise_discount_tl].gsub(',', '').to_f * COURSE
        game[:discount_pct]     = game_raw.at('.game-collection-item-discount-bonus')&.text&.to_i&.abs
        game[:discount_end_raw] = game_raw.at('.game-collection-item-end-date')&.text
      end
      game[:image_link_raw]  = game_raw.at('img.game-collection-item-image')['content']
      game[:data_source_url] = data_source_url
      game[:link]            = SITE + game_raw.at('a')['href']
      game[:url_end_uniq]    = game[:link].split('/')[-1]
      games << game
    end
    games
  end

  private

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
