require_relative '../models/oc_run'
require_relative '../models/oc_product'
require_relative '../models/oc_product_description'
require_relative '../models/oc_product_to_category'
require_relative '../models/oc_product_to_store'
require_relative '../models/oc_product_to_layout'

require_relative '../models/sony_game'
require_relative '../models/sony_game_intro'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'
require_relative '../models/sony_game_additional_file'

class Keeper < Hamster::Keeper
  PS5_CATEGORY_ID = 181
  PS4_CATEGORY_ID = 180

  def initialize
    super
    @count           = 0
    @menu_id_count   = 0
    @run_id          = run.run_id
    @saved           = 0
    @updated         = 0
    @sort_order      = 0
    @skipped         = 0
    @updated_lang    = 0
    @updated_desc    = 0
  end

  attr_reader :run_id, :saved, :updated, :skipped, :updated_lang, :updated_menu_id, :updated_desc
  attr_accessor :count

  def status=(new_status)
    run.status = new_status
  end

  def status
    run.status
  end

  def finish
    run.finish
  end

  def list_last_popular_game
    sg = SonyGame.includes(:sony_game_additional, :sony_game_intro)
            .active_games([settings['parent_ps5'], settings['parent_ps4']])
            .order(menuindex: :asc).limit(10) # !!! limit => settings['limit_export']
    sg.each do |game|
      @sort_order += 1
      oc_product = OcProduct.create(
        price: game.sony_game_additional.price, model: game.sony_game_additional.article,
        sku: game.sony_game_additional.article, upc: game.sony_game_additional.janr, ean: 'yuyuyu', jan: 'klklkl',
        isbn: 'mxnc', mpn: 'pcpcpcp', location: 'Turkish', stock_status_id: 2, manufacturer_id: 4, tax_class_id: 3,
        date_added: Time.now, date_modified: Time.now, sort_order: @sort_order, status: 1
      )
      desc = oc_product.build_oc_product_description(
        language_id: 1, name: game.pagetitle, description: game.content, tag: game.pagetitle,
        meta_title: game.pagetitle, meta_description: game.description[0..50], meta_keyword: game.pagetitle,
        meta_h1: game.pagetitle, quantity: 9999
      )
      desc.save
      layout = oc_product.build_oc_product_to_layout(store_id: 0, layout_id: 0)
      layout.save

      store = oc_product.build_oc_product_to_store
      store.save
      if game.sony_game_additional.platform.match?(/PS5, PS4/)
        category_ps5 = oc_product.oc_product_to_category.build(category_id: PS5_CATEGORY_ID, main_category: 1)
        category_ps5.save
        category_ps4 = oc_product.oc_product_to_category.build(category_id: PS4_CATEGORY_ID)
        category_ps4.save
      elsif game.sony_game_additional.platform.match?(/PS5/)
        category_ps5 = oc_product.oc_product_to_category.build(category_id: PS5_CATEGORY_ID, main_category: 1)
        category_ps5.save
      elsif game.sony_game_additional.platform.match?(/PS4/)
        category_ps4 = oc_product.oc_product_to_category.build(category_id: PS4_CATEGORY_ID, main_category: 1)
        category_ps4.save
      end
    rescue => e
      puts e.message.red
      binding.pry
    end
  end

  private

  def run
    RunId.new(OcRun)
  end
end
