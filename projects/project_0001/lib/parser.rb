class Parser < Hamster::Parser
  BAD_WORDS = %r{телефон|оплата|почта|email|каталог|вопросам|установка}

  def initialize(**page)
    super
    @parsed = 0
    @html   = Nokogiri::HTML(page[:html])
    @debug  = commands[:debug]
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
    puts @html.at('link[rel="canonical"]')['href'] if @debug
    data = {}
    data[:pagetitle] = @html.at('div.product-content h1').text
    data[:introtext] = @html.at('div.product-content div.clearfix div.user-inner')&.text
    @html.at('div.product-content div.clearfix div.user-inner').remove
    data[:content] = form_content

    data[:article] = @html.at('div.product-content div.infoDigits').text.gsub('Артикул:', '').strip

    data
  rescue => e
    binding.pry
  end

  private

  def form_content
    raw_content = @html.at('div.product-content div.user-inner')
    return if raw_content&.text.blank?

    raw_content_children = raw_content.children
    first_bad_word       = raw_content_children.find { |i| i.text.downcase.match?(BAD_WORDS) }
    content = first_bad_word ? clear_content(raw_content_children, first_bad_word) : raw_content.to_html

    binding.pry if content.text.downcase.match?(BAD_WORDS)

    content
  end

  def clear_content(raw_content_children, first_bad_word)
    first_bad_word_index = raw_content_children.index(first_bad_word)
    raw_content_children[0..first_bad_word_index - 1].to_html
  end

  def make_alias(url)
    alias_raw     = url.split('/')[-2..-1]
    alias_raw[-1] = alias_raw[-1][0..120]
    alias_raw     = alias_raw.reverse.join('-')[0..120]
    URI.decode_www_form(alias_raw)[0][0] if alias_raw.match?(/%/)
  end
end
