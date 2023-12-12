require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/exporter'
require 'net/ftp'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
    @debug  = commands[:debug]
    @pages  = 0
  end

  def export
    keeper.status = 'exporting'
    keeper.list_last_popular_game
  end

  private

  attr_reader :keeper

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
