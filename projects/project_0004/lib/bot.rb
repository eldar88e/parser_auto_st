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
        elsif message.text == 'report_games'
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
      Hомер запуска: #{data.id}\nСтатус: #{data.status}\n
      Дата запуска: #{(data.created_at + 3.hours).strftime("%e %B %Y %T")}\n
      Дата финиша: #{(data.updated_at + 3.hours).strftime("%e %B %Y %T")}
    MESSAGE
  end

  def report_games
    manager.report_games
    binding.pry
  end
end
