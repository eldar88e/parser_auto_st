require_relative 'message'

class Bot
  def initialize
    @token     = ENV['TELEGRAM_BOT_TOKEN']
    @messenger = Message.new
  end

  def run
    Telegram::Bot::Client.run(@token) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          handle_callback(bot, message)
        when Telegram::Bot::Types::Message
          handle_message(bot, message)
        end
      end
    end
  end

  private

  attr_reader :messenger

  def vv(message)
    if message.text == 'commands'
      bot.api.send_message(chat_id: message.chat.id, text: commands)
    elsif message.text == 'run_last'
      bot.api.send_message(chat_id: message.chat.id, text: run_last)
    elsif message.text == 'report'
      bot.api.send_message(chat_id: message.chat.id, text: report_games)
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Не верные данные!\n #{message.text}")
    end
  end

  def handle_callback(bot, message)
    return unless messenger.respond_to?(message.data.to_sym)

    text = messenger.send(message.data.to_sym)
    bot.api.send_message(chat_id: message.from.id, text: text)
  end

  def handle_message(bot, message)
    case message.text
    when '/start'
      send_keyboard(bot, message.chat.id)
    end
  end

  def send_keyboard(bot, chat_id)
    keyboard = [[
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Последний запуск', callback_data: 'run_last'),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Отчет', callback_data: 'report_games')
    ]]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
    bot.api.send_message(chat_id: chat_id, text: 'Выберите кнопку:', reply_markup: markup)
  end
end
