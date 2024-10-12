require_relative '../models/turkish_run'
require_relative '../models/ukraine_run'
require_relative '../models/india_run'
require_relative '../models/ps_ua_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'

class ModelManager < Hamster::Keeper

  def run_last
    [TurkishRun.last, UkraineRun.last, IndiaRun.last, PsUaRun.last]
  end

  def report_games
    SonyGame.where(parent: [settings['parent_ps5'], settings['parent_ps4'], 21, 22, 24, 25])
  end
end
