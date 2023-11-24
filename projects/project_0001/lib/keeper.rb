require_relative '../models/sony_game_run'
require_relative '../models/sony_game'

class Keeper
  PARENT      = 218
  TEMPLATE_ID = 10
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
      game_db = SonyGameAdditional.find_by(data_source_url: game[:additional][:data_source_url]) # , deleted: 0
      next if game_db && game_db[:deleted] == 1

      game[:additional][:run_id]         = run_id
      game[:additional][:touched_run_id] = run_id
      keys = %i[data_source_url price old_price price_bonus]
      md5  = MD5Hash.new(columns: keys)
      game[:additional][:md5_hash] = md5.generate(game[:additional].slice(*keys))

      if game_db && game_db[:md5_hash] == game[:additional][:md5_hash]
        # game_db.update(touched_run_id: run_id)
      elsif game_db && game_db[:md5_hash] != game[:additional][:md5_hash]
        game_db.update(game[:additional])
      else
        pagetitle                 = game[:main][:pagetitle]
        game[:main][:longtitle]   = pagetitle
        game[:main][:description] = form_description(pagetitle)
        game[:main][:parent]      = PARENT
        game[:main][:publishedon] = Time.current.to_i
        game[:main][:createdon]   = Time.current.to_i
        game[:main][:alias]       = game[:additional][:data_source_url].split('/')[-2..-1].reverse.join('-')
        game[:main][:alias]       = TEMPLATE_ID
        #возможно еще нужно добавить поля
        # game[:main][:menuindex]

        SonyGame.store(game)
      end
    rescue => e
      puts e
      binding.pry
    end
  end

  private

  def form_description(title)
    <<~DESCR.gsub(/\n/, '')
      Игра #{title}. Купить игру #{title[0..100]} сегодня по выгодной цене. Доставка - СПБ, Москва и вся Россия. 
      Вы искали игру #{title[0..100]} где купить? - Конечно же в Open-PS.ru! >> 100% гарантия от блокировок. 
      Поддержка и консультация, акции и скидки.
    DESCR
  end

  def run
    RunId.new(SonyGameRun)
  end

  def correct_date(date)
    year_raw = date.match(/-\d{4}$/).to_s
    date.sub!(year_raw, '')
    (year_raw.sub('-', '') + '-' + date).to_date
  end
end
