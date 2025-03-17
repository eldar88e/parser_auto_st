class Parser < Hamster::Parser
  def initialize(**page)
    super
    @parsed = 0
    @html   = Nokogiri::HTML(page[:html])
  end

  attr_reader :parsed

  def parse_title
    @html.css('h1.curr_cat').text
  end

  def parse_list
    @html.css('div.categories-wrap div.category-item').map { |i| i.at('a')['href'] }
  end

  def parse_product_list
    @html.css('article.items-wrap div.product-item').map { |i| i.at('a')['href'] }
  end

  def parse
    puts @html.at('link[rel="canonical"]')['href']
    data = {}
    data[:pagetitle] = @html.at('div.product-content h1').text
    data[:longtitle] = data[:pagetitle]
    data[:article]   = @html.at('div.product-content div.infoDigits').text.gsub('Артикул:', '').strip
    data[:introtext] = @html.at('div.product-content div.clearfix div.user-inner')&.text
    @html.at('div.product-content div.clearfix div.user-inner').remove
    data[:content] = form_content
    data
  rescue => e
    binding.pry
  end

  private

  def form_content
    content = @html.at('div.product-content div.user-inner')&.text
    return if content.blank?

    content.gsub!('Информация по установке здесь')
    content.strip
    if content.downcase.match?(/Телефон|оплата|почта|email|каталог/)
      binding.pry
    end
  end

  def make_alias(url)
    alias_raw     = url.split('/')[-2..-1]
    alias_raw[-1] = alias_raw[-1][0..120]
    alias_raw     = alias_raw.reverse.join('-')[0..120]
    URI.decode_www_form(alias_raw)[0][0] if alias_raw.match?(/%/)
  end
end
