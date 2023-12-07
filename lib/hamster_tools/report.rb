# frozen_string_literal: true

module Hamster
  module HamsterTools
    def report(to: nil, message:, use: :telegram)
      initialize

      unless message.present?
        log 'An empty message has been sent to Telegram!', :red
        return
      end
      
      case use
      when :telegram
        tg_send(message)
      else
        log "Cannot use such messenger as #{use.to_s.capitalize}!", :red
      end
    end

    def report_csv(csv_string, message)
      initialize

      [@raw_users.to_s.split(',')].flatten.each do |user_id|
        Telegram::Bot::Client.run(@token_) do |bot|
          bot.api.send_document(
            chat_id: user_id,
            document: Faraday::UploadIO.new(StringIO.new(csv_string), 'text/csv', 'games.csv'),
            caption: message
          )
        end
      end
    rescue => e
      binding.pry
      Hamster.logger.error e.message
      puts e.message.red if commands[:debug]
    end
    
    private

    def initialize
      @token_    ||= ENV['TELEGRAM_BOT_TOKEN']
      @raw_users ||= settings['telegram_chat_id']

      log 'The recipient of the report cannot be found!', :red unless @raw_users
    end
    
    def tg_send(text)
      [@raw_users.to_s.split(',')].flatten.each do |user_id|
        message_limit = 4000
        message_count = text.size / message_limit + 1
        Telegram::Bot::Client.run(@token_) do |bot|
          message_count.times do
            splitted_text = text.chars
            text_part     = splitted_text.shift(message_limit).join
            bot.api.send_message(chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2')
          end
        rescue => e
          Hamster.logger.error e.message
          puts e.message.red if commands[:debug]
        end
      end
      nil
    end
    
    def escape(text)
      text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~`>#+=|{}.!])/, '\\\\\1')
    end
  end
end
