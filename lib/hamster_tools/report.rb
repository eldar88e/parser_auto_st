# frozen_string_literal: true

module Hamster
  module HamsterTools
    def report(to:, message:, use: :telegram)
      @_s_    = Storage.new
      @_user_ = to

      unless @_user_
        log 'The recipient of the report cannot be found!', :red
        return
      end
      
      case use
      when :telegram
        tg_send(message)
      else
        log "Cannot use such messenger as #{use.to_s.capitalize}!", :red
      end
    end
    
    private
    
    def tg_send(text)
      message_limit = 4000
      message_count = text.size / message_limit + 1
      Telegram::Bot::Client.run(@_s_.telegram) do |bot|
        message_count.times do
          splitted_text = text.chars
          text_part     = splitted_text.shift(message_limit).join
          bot.api.send_message(chat_id: @_user_.telegram, text: escape(text_part), parse_mode: 'MarkdownV2')
        end
      end
    end
    
    def escape(text)
      text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~`>#+=|{}.!])/, '\\\\\1')
    end
  end
end
