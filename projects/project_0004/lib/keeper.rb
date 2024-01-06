require_relative '../models/sony_game_run'
require_relative '../models/sony_game_ua_run'
require_relative '../models/sony_game'
require_relative '../models/sony_game_category'
require_relative '../models/sony_game_additional'

class Keeper < Hamster::Keeper

  def run_last
    SonyGameRun.last
  end
end
