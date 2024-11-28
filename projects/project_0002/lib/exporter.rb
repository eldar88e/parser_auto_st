require_relative '../../../concerns/game_modx/exporter'

class Exporter < Hamster::Harvester
  include GameModx::Exporter

  def initialize(keeper)
    super
    @keeper = keeper
  end
end
