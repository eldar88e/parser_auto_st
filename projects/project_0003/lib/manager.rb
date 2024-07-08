require_relative '../lib/keeper'
require 'net/ftp'

class Manager < Hamster::Harvester
  def initialize
    super
    @parse_count = 800
    @keeper = Keeper.new(@parse_count)
    @debug  = commands[:debug]
    @pages  = 0
  end

  def import
    notify 'Importing started' if @debug
    keeper.import_top_games
    notify make_message

    keeper.delete_not_touched
    notify "‼️ Deleted: #{keeper.count[:deleted]} old UA games" if keeper.count[:deleted] > 0

    cleared_cache = false
    if !keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?
      clear_cache
      cleared_cache = true
    end

    keeper.finish
    notify '👌 The UA import succeeded!'
  rescue => error
    Hamster.logger.error error.message
    Hamster.report message: error.message
    @debug = true
    clear_cache if !cleared_cache && (!keeper.count[:saved].zero? || !keeper.count[:updated].zero? || !keeper.count[:deleted].zero?)
  end

  private

  attr_reader :keeper

  def clear_cache
    ftp_host = ENV.fetch('FTP_HOST')
    ftp_user = ENV.fetch('FTP_LOGIN')
    ftp_pass = ENV.fetch('FTP_PASS')

    Net::FTP.open(ftp_host, ftp_user, ftp_pass) do |ftp|
      ftp.chdir('/core/cache/context_settings/web')
      delete_files(ftp)
      ftp.chdir('/core/cache/resource/web/resources')
      delete_files(ftp)
    end
    notify "The cache has been emptied." if @debug
  rescue => e
    message = "Please delete the ModX cache file manually!\nError: #{e.message}"
    notify(message, :red, :error)
  end

  def delete_files(ftp)
    list = ftp.nlst
    list.each do |i|
      try = 0
      begin
        try += 1
        ftp.delete(i)
      rescue Net::FTPPermError => e
        Hamster.logger.error e.message
        sleep 5 * try
        retry if try > 3
      end
    end
  end

  def make_message
    message = ""
    message << "✅ Saved: #{keeper.count[:saved]} new UA games;\n" unless keeper.count[:saved].zero?
    message << "✅ Updated prices: #{keeper.count[:updated]} UA games;\n" unless keeper.count[:updated].zero?
    message << "✅ Restored prices: #{keeper.count[:restored]} UA games;\n" unless keeper.count[:restored].zero?
    message << "✅ Updated menuindex: #{keeper.count[:updated_menu_id]} UA games;\n" unless keeper.count[:updated_menu_id].zero?
    message << "✅ Imported: #{@parse_count} UA games."
    message
  end

  def notify(message, color=:green, method_=:info)
    Hamster.logger.send(method_, message)
    Hamster.report message: message
    puts color.nil? ? message : message.send(color) if @debug
  end
end
