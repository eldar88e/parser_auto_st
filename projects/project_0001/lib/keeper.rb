require_relative '../models/sony_game_run'
require_relative '../models/sony_game'

class Keeper
  def initialize
    @count  = 0
    @run_id = run.run_id
  end

  attr_reader :run_id
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

  def save_games(games)
    games.each do |game|
      game[:run_id] = run_id
      game[:touched_run_id] = run_id
      keys = %i[name link prise_tl prise_discount_tl]
      md5 = MD5Hash.new(columns: keys)
      game[:md5_hash] = md5.generate(game.slice(*keys))
      game_db = SonyGame.find_by(link: game[:link], deleted: 0)
      if game_db && game_db[:md5_hash] == game[:md5_hash]
        game_db.update(touched_run_id: run_id)
      elsif game_db && game_db[:md5_hash] != game[:md5_hash]
        game_db.update(deleted: 1)
        SonyGame.store(game)
      else
        SonyGame.store(game)
      end

    rescue => e
      puts e
      binding.pry
    end
  end

  private

  def run
    RunId.new(SonyGameRun)
  end

  def correct_date(date)
    year_raw = date.match(/-\d{4}$/).to_s
    date.sub!(year_raw, '')
    (year_raw.sub('-', '') + '-' + date).to_date
  end
end
