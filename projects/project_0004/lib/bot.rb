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
          last = run_last
          bot.api.send_message(chat_id: message.chat.id, text: last)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Не верные данные!\n #{message.text}")
        end
      rescue Telegram::Bot::Exceptions::ResponseError => e
        puts e.class
        puts e.message
        binding.pry
      end
    end
  end

  private

  attr_reader :manager

  def run_last
    data = manager.run_last
    "Hомер запуска: #{data.id}\nСтатус: #{data.status}\nДата запуска: #{data.created_at}\nДата финиша: #{data.updated_at}"
  end
end
