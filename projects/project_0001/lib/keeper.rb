require_relative '../models/run'
require_relative '../models/modx_site_content'
require_relative '../models/modx_site_tmplvar_contentvalues'

class Keeper < Hamster::Keeper
  ARTICLE_TV_ID     = 9
  USER_ID           = 6
  T_PRODUCT_ID      = 13
  T_SUB_CATEGORY_ID = 17
  T_CATEGORY_ID     = 14
  DEFAULT_COLUMNS   = {
    published: 1, publishedon: Time.current.to_i, publishedby: USER_ID, isfolder: 1,
    createdby: USER_ID, createdon: Time.current.to_i, properties: '{"ms2gallery":{"media_source":"2"}}'
  }.freeze

  def initialize(settings)
    @count = { saved: 0, updated: 0 }
  end

  attr_reader :count

  def find_or_create(parent, content, sub = nil)
    content_db = parent.children.find_or_initialize_by(alias: content[:alias]) # TODO: убрать _or_initialize
    # return content_db if content_db # TODO: раскомментировать !!!

    prepare_additional_content_attr(content, sub)
    content[:parent]   = parent.id
    content[:isfolder] = 0 if sub == :product
    content_db.update!(content)
    content_db
  rescue => e
    puts e.message
    binding.pry
  end

  def save_product(parent, product)
    article = product.delete(:article)

    item = find_or_create(parent, product, :product)

    tv_article = item.tv.find_or_initialize_by(tmplvarid: ARTICLE_TV_ID)
    tv_article.update!(value: article)

    @count[:saved] += 1
  end

  private

  def form_template_id(content, sub)
    return content[:template] = T_PRODUCT_ID if sub == :product

    content[:template] = sub ? T_SUB_CATEGORY_ID : T_CATEGORY_ID
  end

  def prepare_additional_content_attr(content, sub)
    normalize_title(content)
    content[:description] = form_description(content[:title])
    form_template_id(content, sub)
    content.merge!(DEFAULT_COLUMNS)
  end

  def normalize_title(product)
    title = product[:pagetitle]
    return if title.size <= 70

    normal_title = title[0..69]
    product[:pagetitle] = normal_title
    product[:longtitle] = normal_title
    product[:content]   = "<p>#{title}<p>" + product[:content].to_s
  end

  def form_description(title)
    <<~DESCR.gsub(/\n/, '')
      Широкий выбор автостёкол для спецтехники #{title}.
      Производство за 8 часов, быстрая доставка и профессиональная установка в Уфе.
      Закажите стекло для спецтехники KOMATSU, HITACHI, LIEBHERR, МТЗ и других производителей!
    DESCR
  end
end
