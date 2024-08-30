class Parser < Hamster::Parser

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
  end

  def parse_supplement
    return if @html.to_s.match?(/504 Gateway Time-out/)

    supplement = {}
    supplement[:source_img]    = @html.at('div.cm-preview-wrapper a')['href'].gsub(/\A\/+/, 'https://')
    supplement[:source_url]    = @html.at('head link[rel="canonical"]')['href']
    supplement[:pagetitle]     = @html.at('.ut2-pb__title').text
    supplement[:article]       = @html.at('.ty-sku-item span.ty-control-group__item').text.to_i
    supplement[:price]         = @html.at('.ty-product-prices .ut2-pb__price-actual').text.strip.scan(/\d/).join.to_i
    price_old_raw              = @html.at('.ty-product-prices .ty-list-price')
    supplement[:old_price]     = price_old_raw.text.strip.scan(/\d/).join.to_i if price_old_raw
    supplement[:delivery_time] = @html.at('.ut2-pb__advanced-option .ty-control-group__item')
                                      .text.strip.scan(/\d/).join.to_i
    supplement[:content]       = @html.at('.content-description').to_html.strip

    params_raw = @html.css('.cm-ab-similar-filter-container > div')
    get_params(params_raw, supplement)

    supplement
  end

  private

  def get_params(params_raw, supplement)
    params_raw.each do |params|
      label = params.at('.ty-product-feature__label').text
      value = params.at('.ty-product-feature__value').text.strip
      if label.match?(/Бренд/)
        supplement[:vendor] = value
      elsif label.match?(/Форма выпуска/)
        supplement[:release_form] = value
      elsif label.match?(/Страна производитель/)
        supplement[:made_in] = value
      elsif label.match?(/Условия хранения/)
        supplement[:storage_conditions] = value
      elsif label.match?(/Примечание/)
        supplement[:note] = value
      elsif label.match?(/Количество в упаковке/)
        supplement[:quantity_in_package] = value
      elsif label.match?(/Дозировка/)
        supplement[:dosage] = value
      elsif label.match?(/Единица измерения/)
        supplement[:unit] = value
      elsif label.match?(/Действующее вещество/)
        supplement[:active_substance] = value
      elsif label.match?(/Целевая аудитория:/)
        supplement[:target_audience] = value
      elsif label.match?(/Состав:/)
        supplement[:compound] = value
      elsif label.match?(/Способ применения/)
        supplement[:mode_application] = value
      end
    end
  end
end
