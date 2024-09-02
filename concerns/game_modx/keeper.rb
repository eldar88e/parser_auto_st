module GameModx
  module Keeper
    def get_game_without_rus
      ids    = SonyGame.active_games([self.class::PARENT_PS5, self.class::PARENT_PS4]).pluck(:id)
      result = SonyGameAdditional.where(id: ids, rus_voice: 0).limit(settings['limit_upd_lang'])
      check  = @settings[:touch_update_desc].nil? ||
        @settings[:day_all_lang_scrap].to_i == Date.current.day && Time.current.hour < 12
      check ? result : result.where(run_id: run_id)
    end

    def save_lang(data, model)
      model.update(data)
      @count[:updated_lang] += 1 if model.saved_changes?
    rescue ActiveRecord::StatementInvalid => e
      Hamster.logger.error "ID: #{model.id} | #{e.message}"
    end
  end
end