require_relative '../lib/bot'

class Manager < Hamster::Harvester
  def bot
    telegram_bot = Bot.new

    telegram_bot.run
  end
end
