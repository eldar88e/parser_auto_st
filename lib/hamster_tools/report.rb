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

    def send_file(csv_string, file_name)
      initialize

      #type_     = type == :gz ? 'application/x-gzip' : 'text/csv'
      #file_name = type == :gz ? 'games.csv.gz' : 'games.csv'
      message   = "Archived CSV file containing the #{settings['limit_export']} most popular PlayStation games."
      #message   = 'Archived ' + message if type == :gz
      [@raw_users.to_s.split(',')].flatten.each do |user_id|
        Telegram::Bot::Client.run(@token_) do |bot|
          bot.api.send_document(
            chat_id: user_id,
            document: Faraday::UploadIO.new(StringIO.new(csv_string), 'application/x-gzip', file_name),
            caption: message
          )
        end
      end
    rescue => e
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
