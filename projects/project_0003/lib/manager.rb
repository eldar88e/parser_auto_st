require_relative '../lib/keeper'
require 'net/ftp'
require_relative '../../../concerns/game_modx/manager'

class Manager < Hamster::Harvester
  include GameModx::Manager

  def initialize
    super
    @parse_count = 800
    @keeper      = Keeper.new({ parse_count: @parse_count })
    @debug       = commands[:debug]
    @pages       = 0
  end

  def import
    notify 'Importing started' if @debug
    keeper.import_top_games
    notify make_message

    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old #{COUNTRY_FLAG[keeper.class::MADE_IN]} game(s)" if keeper.count[:deleted] > 0

    clr_cache = false
    clr_cache = clear_cache if keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0

    keeper.finish
    notify '👌 The UA import succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    clear_cache if !clr_cache && (keeper.count[:saved] > 0 || keeper.count[:updated] > 0 || keeper.count[:deleted] > 0)
  end
end
