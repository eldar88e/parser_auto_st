require_relative '../models/modx_site_content'
require_relative '../models/modx_site_tmplvar_contentvalues'

class Keeper < Hamster::Keeper
  ARTICLE_TV_ID     = 9
  IMAGE_TV_ID       = 1
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
  end

  def save_product(parent, product)
    article = product.delete(:article)
    item    = find_or_create(parent, product, :product)

    if article.present?
      tv_article = item.tv.find_or_initialize_by(tmplvarid: ARTICLE_TV_ID)
      tv_article.update!(value: article)

      tv_image = item.tv.find_or_initialize_by(tmplvarid: IMAGE_TV_ID)
      tv_image.update!(value: "new/#{article}.jpg")
    end

    @count[:saved] += 1
  end

  private

  def form_template_id(content, sub)
    return content[:template] = T_PRODUCT_ID if sub == :product

    content[:template] = sub ? T_SUB_CATEGORY_ID : T_CATEGORY_ID
  end

  def prepare_additional_content_attr(content, sub)
    content[:longtitle] = content[:pagetitle]
    normalize_title(content)
    content[:description] = form_description(content[:pagetitle])
    form_template_id(content, sub)
    content.merge!(DEFAULT_COLUMNS)
  end

  def normalize_title(product)
    title = product[:pagetitle]
    return if title.size <= 70

    normal_title        = TextTruncator.call({ text: title, max: 70 })
    product[:pagetitle] = normal_title
    product[:longtitle] = normal_title
    product[:content]   = product[:introtext] if product[:content].blank?
    product[:content]   = "<p>#{title}<p>" if product[:content].blank?
    add_corporation_info(product)
  end

  def add_corporation_info(product)
    product[:content] += <<~INFO.squeeze(' ').chomp
      <br/><br/>
      <p>ОПЛАТА:</p>
      <ul class="corporation">
        <li>скидка при оплате наличными;</li>
        <li>безналичный расчет на р/с ООО (с НДС);</li>
        <li>безналичный расчет на р/с ИП (без НДС);</li>
        <li>наличный расчет.</li>
      </ul>
  
      <p>ДОСТАВКА:</p>
      <ul class="corporation">
        <li>самовывоз с нашего склада по адресу: Уфа, ул. Благоварская, д. 4;</li>
        <li>по Уфе нашим транспортом;</li>
        <li>транспортными компаниями Деловые линии, ПЭК, GTD по России, Белоруссии и в Казахстан.</li>
      </ul>

      <p>По всем вопросам:</p>
      <ul class="corporation">
        <li>Телефон/ватс-ап/телеграмм: 8 (917) 480-80-70;</li>
        <li>Эл.почта: 2747410@mail.ru</li>
      </ul>
    INFO
  end

  def form_description(title)
    <<~DESCR.squeeze(' ').chomp
      Широкий выбор автостёкол для спецтехники #{title}.
      Производство за 8 часов, быстрая доставка и профессиональная установка в Уфе и по всей России.
      Закажите стекло для спецтехники KOMATSU, HITACHI, LIEBHERR, МТЗ и других производителей!
    DESCR
  end
end
