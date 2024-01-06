require_relative 'model_manager'

class Bot < Hamster::Harvester
  def initialize(*_)
    super
    @manager = ModelManager.new
  end

  def run
    Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
      bot.listen do |message|
        if message.text == 'run_last'
          bot.api.send_message(chat_id: message.chat.id, text: run_last)
        elsif message.text == 'report'
          bot.api.send_message(chat_id: message.chat.id, text: report_games)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Не верные данные!\n #{message.text}")
        end
      end
    end
  end

  private

  attr_reader :manager

  def run_last
    data = manager.run_last
    <<~MESSAGE
      Hомер запуска: #{data.id}
      Статус: #{data.status}
      Дата запуска: #{(data.created_at + 3.hours).strftime("%e %B %Y %T")}
      Дата финиша: #{(data.updated_at + 3.hours).strftime("%e %B %Y %T")}
    MESSAGE
  end

  def report_games
    games = manager.report_games
    <<~MESSAGE
      Турецкие игры:
        - Активные: #{games.where(deleted: 0, published: 1).where(parent: [settings['parent_ps5'], settings['parent_ps4']]).size}
        - Удаленные: #{games.where(deleted: 1).where(parent: [settings['parent_ps5'], settings['parent_ps4']]).size}
        - Снятые с публикации: #{games.where(published: 0).where(parent: [settings['parent_ps5'], settings['parent_ps4']]).size}
      Украинские игры:
        - Активные: #{games.where(deleted: 0, published: 1).where(parent: [21, 22]).size}
        - Удаленные: #{games.where(deleted: 1).where(parent: [21, 22]).size}
        - Снятые с публикации: #{games.where(published: 0).where(parent: [21, 22]).size}
    MESSAGE
  end
end
