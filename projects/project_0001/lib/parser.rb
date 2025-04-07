class Parser < Hamster::Parser
  BAD_WORDS = %r{телефон|оплата|почта|email|каталог|вопросам|установк|komexpress}i
  COMPANY   = '«Авторитет»'.freeze

  def initialize(**page)
    super
    @parsed = 0
    @html   = Nokogiri::HTML(page[:html])
    @debug  = commands[:debug]
  end

  attr_reader :parsed

  def parse_brand
    @html.css('div.user-inner')&.text&.strip&.gsub("\n", '<br/>')
  end

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
    data[:introtext] = form_introtext
    data[:content]   = form_content
    data[:article]   = @html.at('div.product-content div.infoDigits').text.gsub('Артикул:', '').strip
    data
  end

  private

  def form_introtext
    tags   = 'div.product-content div.clearfix div.user-inner'
    result = @html.at(tags)&.text&.gsub!('закаленное', 'триплекс')
    @html.at(tags).remove
    result
  end

  def form_content
    raw_content = @html.at('div.product-content div.user-inner')
    return if raw_content&.text.blank?

    prepare_content(raw_content)
    raw_content_children = raw_content.children
    first_bad_word       = raw_content_children.find { |i| i.text.match?(BAD_WORDS) }
    content              = first_bad_word ? clear_content(raw_content_children, first_bad_word) : raw_content.to_html
    content.gsub!('закаленное', 'триплекс')
    content
  end

  def prepare_content(raw_content)
    raw_content.css('a')&.each(&:remove)
    raw_content.traverse do |node|
      if node.text? && node.content.match?(/komexpress|комэкспресс/i)
        node.content = node.content.gsub(/komexpress|комэкспресс/i, COMPANY)
      end
    end
  end

  def clear_content(raw_content_children, first_bad_word)
    first_bad_word_index = raw_content_children.index(first_bad_word)
    Hamster.report message: "Пустой контент #{@html.at('link[rel="canonical"]')['href']}" if first_bad_word_index.zero? # TODO: убрать !!!
    first_bad_word_index.zero? ? '' : raw_content_children[0..first_bad_word_index - 1].to_html
  end

  def make_alias(url)
    alias_raw     = url.split('/')[-2..-1]
    alias_raw[-1] = alias_raw[-1][0..120]
    alias_raw     = alias_raw.reverse.join('-')[0..120]
    URI.decode_www_form(alias_raw)[0][0] if alias_raw.match?(/%/)
  end
end
