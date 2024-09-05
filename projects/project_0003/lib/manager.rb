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
    notify "‼️ Deleted: #{keeper.count[:deleted]} old UA games" if keeper.count[:deleted] > 0

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

  private

  def make_message
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new UA games;\n" unless keeper.count[:saved].zero?
    message << "✅ Restored: #{keeper.count[:restored]} UA games;\n" unless keeper.count[:restored].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} UA games;\n" unless keeper.count[:updated].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} UA games;\n" unless keeper.count[:updated_menu_id].zero?
    message << "✅ Imported: #{@parse_count} UA games."
    message
  end
end
