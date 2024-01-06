class Bot < Hamster::Harvester

  def run
    Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
      bot.listen do |message|
        if message.text
          bot.api.send_message(chat_id: message.chat.id, text: "Это текст")
          binding.pry
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Не верные данные!\n #{message.text}")
        end
      end
    end
  end
end
