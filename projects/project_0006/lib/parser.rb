require_relative '../models/sony_game_additional'
require_relative '../../../concerns/game_modx/parser'

class Parser < Hamster::Parser
  include GameModx::Parser

  EXCHANGE_RATE_MIN = 1.5 # До 8000 RS - 1.5р за 1 RS
  EXCHANGE_RATE_MAX = 1.4 # От 8000 RS - 1.4р за 1 RS

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

  def parse_list_games_in
    games     = []
    games_raw = @html.css('div.game-collection-item')
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
      game[:additional][:type_game]         = @translator.translate_type(type_game_raw)
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

  def formit_lang(info)
    result              = {}
    result[:release]    = info[:release]
    result[:publisher]  = info[:publisher]
    result[:genre]      = form_genres(info[:genres])
    result[:rus_voice]  = exist_rus?(info)
    result[:rus_screen] = exist_rus?(info, 'screen')
    result
  end

  def exist_rus?(info, params='voice')
    info.any? { |key, value| key.to_s.match?(%r[#{params}]) && value.downcase.match?(/russia/) }
  end

  def form_genres(genre_raw)
    return 'Другое' unless genre_raw.present?

    genre = genre_raw.split(', ').map(&:strip).uniq.sort.join(', ')
    translate_genre(genre)
  end

  def translate_genre(text)
    text.split(', ').map { |i| @translator.translate_genre(i) }.sort.join(', ')
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
end
