require_relative '../models/run'
require_relative '../models/modx_site_content'
require_relative '../models/modx_site_tmplvar_contentvalues'

class Keeper < Hamster::Keeper
  ARTICLE_TV_ID = 9

  def initialize(settings)
    @count = { saved: 0, updated: 0 }
  end

  attr_reader :count

  def save_product(product)
    article = product.delete(:article)
    form_content(product)
    item    = ModxSiteContent.find_or_initialize_by(uri: product[:uri])
    # product[:properties] = '{"ms2gallery":{"media_source":"2"}}'
    item.update!(product)
    tv_article = item.tv.find_or_initialize_by(tmplvarid: ARTICLE_TV_ID)
    tv_article.update!(value: article)
    @count[:saved] += 1
  end

  private

  def form_content(product)
    title = product[:pagetitle]
    if title.size > 70
      product[:pagetitle] = title[0..69]
      product[:longtitle] = title[0..69]
      product[:content] = "<p>#{title}<p>" + product[:content]
    end
  end

  def form_description(title)
    <<~DESCR.gsub(/\n/, '')
      Стекло #{title}. Купить.
    DESCR
  end
end
