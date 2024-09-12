module GameModx
  module Keeper
    PROPERTIES = '{"stercseo":{"index":"1","follow":"1","sitemap":"1","priority":"0.5","changefreq":"weekly"}}'
    SOURCE     = 3

    def initialize(settings)
      super
      @settings = settings
      @run_id   = run.run_id
      @count    = { count: 0, menu_id_count: 0, saved: 0, updated: 0, updated_menu_id: 0,
                    skipped: 0, deleted: 0, updated_lang: 0, updated_desc: 0, restored: 0 }
      @quantity = settings[:parse_count]
      @ps4_path = get_parent_alias self.class::PARENT_PS5
      @ps5_path = get_parent_alias self.class::PARENT_PS4
    end

    attr_reader :run_id, :count

    def status=(new_status)
      run.status = new_status
    end

    def status
      run.status
    end

    def finish
      run.finish
    end

    def fetch_game_without_rus
      ids            = SonyGame.active_games([self.class::PARENT_PS5, self.class::PARENT_PS4]).pluck(:id)
      search         = { id: ids, rus_voice: 0 }
      search[:genre] = [nil, ''] if commands[:genre]
      result         = SonyGameAdditional.where(search).limit(settings['limit_upd_lang'])
      check_day_hour = @settings[:day_all_lang_scrap].to_i == Date.current.day && Time.current.hour < 12
      check_day_hour || commands[:genre] ? result : result.where(run_id: run_id)
    end

    def save_lang(data, model)
      content = data.delete(:content)
      save_content(content, model) if content && model.sony_game.content != content
      model.update(data)
      @count[:updated_lang] += 1 if model.saved_changes?
    rescue ActiveRecord::StatementInvalid => e
      Hamster.logger.error "ID: #{model.id} | #{e.message}"
    end

    def delete_not_touched
      sg = SonyGame.joins(:sony_game_additional).active_games([self.class::PARENT_PS5, self.class::PARENT_PS4])
                   .where.not(sony_game_additional: { touched_run_id: run_id })
      @count[:deleted] += sg.update_all(deleted: 1, deletedon: Time.current.to_i, deletedby: settings['user_id'])
    end

    def list_last_popular_game(limit)
      SonyGame.includes(:sony_game_additional)
              .active_games([self.class::PARENT_PS5, self.class::PARENT_PS4])
              .order(menuindex: :asc).limit(limit)
    end

    private

    def form_block_game_additions(games)
      urls = games.map { |i| i[:additional][:data_source_url] }
      SonyGameAdditional.includes(:sony_game).where(data_source_url: urls)
    end

    def form_start_game_data(game)
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus discount_end_date]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))
      game[:additional][:popular]  = @count[:menu_id_count] < 151
    end

    def check_game(sony_game)
      unless sony_game
        Hamster.logger.error("Game in content table has been removed!")
        return
      end
      return if !sony_game.published

      if sony_game.deleted && sony_game.deletedby == settings['user_id']
        restore_game(sony_game)
        true
      elsif sony_game.deleted
        return
      end
      true
    end

    def restore_game(sony_game)
      sony_game.update(deleted: 0, editedon: Time.current.to_i, editedby: settings['user_id'])
      sony_game.sony_game_additional.update(touched_run_id: run_id)
      @count[:restored] += 1
    end

    def update_date(game, game_add, sony_game)
      check_md5_hash          = game_add[:md5_hash] != game[:additional][:md5_hash]
      start_new_date          = Date.current.prev_month(settings['month_since_release'])
      game[:additional][:new] = (game_add[:release] > start_new_date) if game_add[:release]
      game_add.update(game[:additional]) # For update touched_run_id
      @count[:updated] += 1 if check_md5_hash

      data = { menuindex: @count[:menu_id_count], editedon: Time.current.to_i, editedby: settings['user_id'] }
      sony_game.update(data) && @count[:updated_menu_id] += 1 if @count[:menu_id_count] != sony_game[:menuindex]
    rescue StandardError => e
      binding.pry
    end

    def form_new_game(game, image_link_raw)
      game[:additional][:run_id]    = run_id
      game[:additional][:source]    = SOURCE
      game[:additional][:site_link] = form_link(game[:additional][:janr])
      game[:additional][:image]     = image_link_raw.sub(/720&h=720/, settings['medium_size'])
      game[:additional][:thumb]     = image_link_raw.sub(/720&h=720/, settings['small_size'])
      game[:additional][:made_in]   = self.class::MADE_IN

      crnt_time                  = Time.current.to_i
      game[:main][:longtitle]    = game[:main][:pagetitle]
      game[:main][:parent]       = make_parent(game[:additional][:platform])
      game[:main][:uri]          = make_uri(game[:main][:alias], game[:additional][:platform])
      game[:main][:description]  = form_description(game[:main][:pagetitle])
      game[:main][:publishedon]  = crnt_time
      game[:main][:publishedby]  = settings['user_id']
      game[:main][:createdon]    = crnt_time
      game[:main][:createdby]    = settings['user_id']
      game[:main][:template]     = settings['template_id']
      game[:main][:properties]   = PROPERTIES
      game[:main][:menuindex]    = @count[:menu_id_count]
      game[:main][:published]    = 1
      game[:main][:show_in_tree] = 0

      need_category   = check_need_category(game[:additional][:platform])
      game[:category] = { category_id: self.class::PARENT_PS4 } if need_category
      game[:intro]    = prepare_intro(game[:main])
    end

    def prepare_intro(game, content=nil)
      data = { intro: game[:pagetitle] + ' ' + game[:longtitle] + ' ' + game[:description] }
      data[:intro] += " #{content}" if content.present?
      data
    end

    def make_uri(alias_, platform)
      start = platform.downcase.match?(/ps5/) ? @ps5_path : @ps4_path
      "#{start}/#{alias_}"
    end

    def get_parent_alias(id)
      path_raw = []
      while id != 0
        sg = SonyGame.find(id)
        path_raw << sg.alias
        id = sg.parent
      end
      path_raw.reverse.join('/')
    end

    def make_parent(platform)
      platform.downcase.match?(/ps5/) ? self.class::PARENT_PS5 : self.class::PARENT_PS4
    end

    def check_need_category(platform)
      platform.downcase.match?(/ps4/) && platform.downcase.match?(/ps5/)
    end

    def run
      klass = "#{self.class::MADE_IN}Run".constantize
      @run ||= RunId.new(klass)
    end
  end
end