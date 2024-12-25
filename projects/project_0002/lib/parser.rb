require_relative '../../../concerns/game_modx/parser'

class Parser < Hamster::Parser
  include GameModx::Parser

  MIN_PRICE     = 15
  EXCHANGE_RATE = 4

  def initialize(**page)
    super
    @html       = Nokogiri::HTML(page[:html])
    @translator = Hamster::Translator.new
    @parsed     = 0
  end

  attr_reader :parsed

  def parse_list_games_ua
    games     = []
    games_raw = @html.css('div.game-collection-item')
    games_raw.each do |game_raw|
      game           = { main: {}, additional: {} }
      price_tl_raw   = game_raw.at('span.game-collection-item-price')&.text
      platform       = game_raw.at('.game-collection-item-top-platform').text
      match_date     = %r[\d день|\d+ дня|\d+ дней|\d+ месяца?|\d+ месяцев|\d+ days?|\d+ months?]
      date_raw       = game_raw.at('.game-collection-item-end-date')&.text&.match(match_date).to_s
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

      game[:main][:pagetitle]       = game_raw.at('.game-collection-item-details-title').text
      game[:additional][:platform]  = platform.gsub(' / ', ', ').gsub(/, PS Vita|, PS3/, '')
      type_game_raw                 = game_raw.at('.game-collection-item-type').text
      game[:additional][:type_game] = @translator.translate_type type_game_raw

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

  def formit_lang(info)
    result              = {}
    result[:release]    = info[:выпуск]
    result[:publisher]  = info[:издатель]
    result[:genre]      = form_genres info[:жанры]
    result[:rus_voice]  = exist_rus?(info)
    result[:rus_screen] = exist_rus?(info, 'языки_')
    result[:content]    = @html.at('.psw-l-grid p')&.children&.to_html
    remove_emoji(result[:content]) if result[:content].present?
    result
  end

  def form_genres(genres_raw)
    return 'Другое' unless genres_raw.present?

    genres_raw.split(', ').map(&:strip).uniq.sort.join(', ')
  end

  def exist_rus?(info, params='голос')
    info.any? { |key, value| key.to_s.match?(%r[#{params}]) && value.downcase.match?(/рус/) }
  end

  def make_exchange_rate(price)
    price * EXCHANGE_RATE
  end
end
