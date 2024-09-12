require_relative '../models/run'
require_relative '../models/product'
require_relative '../models/content'
require_relative '../models/intro'

class Keeper < Hamster::Keeper
  SOURCE     = 2
  PROPERTIES = '{"stercseo":{"index":"1","follow":"1","sitemap":"1","priority":"0.5","changefreq":"weekly"}}'

  def initialize(parser_settings)
    super
    @run_id    = run.run_id
    @count     = { count: 0, saved: 0, updated: 0, skipped: 0, deleted: 0, content_updated: 0 }
    @settings  = parser_settings
    @parents   = {}
    @no_parent = []
  end

  attr_reader :run_id, :count, :no_parent

  def status=(new_status)
    run.status = new_status
  end

  def status
    run.status
  end

  def finish
    run.finish
  end

  def save_supplement(product)
    keys                       = %i[title source_url price old_price]
    md5                        = MD5Hash.new(columns: keys)
    product[:md5_hash]         = md5.generate(product.slice(*keys))
    product[:source]           = SOURCE
    product[:main]             = {}
    product[:main][:pagetitle] = product.delete(:pagetitle)
    product[:main][:content]   = product.delete(:content)
    product[:touched_run_id]   = run_id

    save_vendor(product)

    product_db = Product.find_by(source_url: product[:source_url])
    if product_db
      content_db = product_db.content
      if content_db
        return if content_db.deleted || !content_db.published
      else
        Hamster.logger.error "Основная запись в таблице #{Content.table_name} под ID: `#{product_db.id}` удалена!\n"\
                               "Удалите остатки в таблицах или добавте в основную таблицу под этим ID запись."
        return
      end
      update_data(product, product_db, content_db)
    else
      product[:main][:alias]        = product[:source_url].split('/')[-1]
      product[:main][:uri]          = product[:main][:alias]
      product[:main][:template]     = @settings[:template_id]
      product[:main][:properties]   = PROPERTIES
      product[:main][:show_in_tree] = 0
      product[:main][:longtitle]    = product[:main][:pagetitle]
      product[:main][:parent]       = make_parent(product[:source_url])

      if product[:main][:parent].nil?
        @no_parent << product[:source_url]
        return
      end

      product[:main][:description] = form_description(product[:main][:pagetitle])
      cur_time                     = Time.current.to_i
      product[:run_id]             = run_id
      product[:new]                = true
      product[:main][:publishedon] = cur_time
      product[:main][:publishedby] = @settings[:user_id]
      product[:main][:createdon]   = cur_time
      product[:main][:createdby]   = @settings[:user_id]
      product[:main][:published]   = 1
      product[:intro]              = prepare_intro(product[:main])

      Content.store(product)
      @count[:saved] += 1
    end
  end

  private

  def save_vendor(product)
    vendor = product.delete(:vendor)
    return unless vendor

    vendor_db = Vendor.find_by(name: vendor)
    if vendor_db.nil?
      content_vendor = Content.find_by(pagetitle: vendor, parent: 77, template: 16)
      if content_vendor.nil?
        data               = {}
        cur_time          = Time.current.to_i
        data[:template]    = 16
        data[:properties]  = PROPERTIES
        data[:publishedon] = cur_time
        data[:publishedby] = 3
        data[:createdon]   = cur_time
        data[:createdby]   = data[:publishedby]
        data[:parent]      = 77
        data[:published]   = 1
        data[:pagetitle]   = vendor
        data[:description] = data[:pagetitle]
        data[:uri]         = vendor.gsub("İ", 'i').downcase.gsub(/[ _]/, '-').gsub('ç', 'c')
        data[:alias]       = data[:uri]
        data[:class_key]   = 'modDocument'
        data[:description] = data[:pagetitle]
        content_vendor     = Content.create!(data)
      end
      vendor_db = Vendor.create!(name: vendor, resource: content_vendor.id)
    end
    product[:vendor] = vendor_db&.id
  end

  def make_parent(url)
    parent_alias = url.split('/')[-2].gsub(/_/, '-')
    @parents[parent_alias] ||= Content.find_by(alias: parent_alias)&.id
    return @parents[parent_alias] if @parents[parent_alias]

    main_alias = %r[vitaminy-bad-i-pischevye-dobavki]
    if @parents[parent_alias].nil? && parent_alias.match?(/tip-volos/)
      @parents[parent_alias] = Content.find_by(alias: 'dobavki-dlya-volos')&.id
    elsif @parents[parent_alias].nil? && url.match?(main_alias)
      url_splited = url.split('/')
      if url_splited[-4].match?(main_alias)
        crnt_time = Time.current.to_i
        main_info = {}
        main_info[:template]    = 5
        main_info[:properties]  = PROPERTIES
        main_info[:publishedon] = crnt_time
        main_info[:publishedby] = @settings[:user_id]
        main_info[:createdon]   = crnt_time
        main_info[:createdby]   = @settings[:user_id]
        main_info[:parent]      = 13
        main_info[:published]   = 1
        main_info[:isfolder]    = 1
        main_info[:class_key]   = 'msCategory'

        cat_alias               = url_splited[-3]
        main_info[:pagetitle]   = cat_alias
        main_info[:description] = cat_alias
        cat_id                  = Content.find_by(alias: cat_alias)&.id ||
          Content.create!({ alias: cat_alias, uri: "#{cat_alias}/" }.merge(main_info)).id

        sub_cat_alias           = url_splited[-2]
        main_info[:parent]      = cat_id
        main_info[:pagetitle]   = sub_cat_alias
        main_info[:description] = sub_cat_alias
        sub_cat_id = Content.create!({ alias: sub_cat_alias, uri: "#{sub_cat_alias}/" }.merge(main_info)).id
        Hamster.report message: "Add new sub category #{sub_cat_alias} to #{cat_alias}!"
        @parents[sub_cat_alias] = sub_cat_id
      end
    end

    @parents[parent_alias]
  end

  def update_data(data, product_db, content_db)
    content_data = data.delete(:main)
    cur_time     = Time.current
    end_time     = Time.at(content_db.createdon) + 3.month
    data[:new]   = cur_time < end_time if product_db.new
    product_db.update(data)
    @count[:updated] += 1 if product_db[:md5_hash] != data[:md5_hash]
    @count[:skipped] += 1 if product_db[:md5_hash] == data[:md5_hash]

    edite = { editedon: Time.current.to_i, editedby: @settings[:user_id] }
    if content_db[:content] != content_data[:content]
      content_db.update(content_data.merge(edite)) &&  @count[:content_updated] += 1
    end
  end

  def prepare_intro(product)
    { intro: product[:pagetitle] + ' ' + product[:description] }
  end

  def form_description(title)
    @settings[:description].gsub('[title]', title)
  end

  def run
    RunId.new(Run)
  end
end
