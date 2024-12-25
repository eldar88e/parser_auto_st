require_relative 'model_manager'

class Message < Hamster::Keeper
  def initialize
    super
    @manager = ModelManager.new
  end

  def commands
    <<~MESSAGE
    📌 Доступные команды для бота:
      ✅ run_last – для просмотра информации о последнем запуске парсера
      ✅ report_games – отчет о количестве активных, не опубликованых и удаленных играх
    MESSAGE
  end

  def run_last
    runs       = manager.run_last
    tr_data    = runs[0]
    ua_data    = runs[1]
    in_date    = runs[2]
    ps_ua_data = runs[3]
    "📌 Информация о 🇹🇷 парсере:\n" + make_run_text(tr_data) +
      "\n📌 Информация о 🇺🇦 парсере:\n" + make_run_text(ua_data) +
      "\n📌 Информация о 🇮🇳 парсере:\n" + make_run_text(in_date) +
      "\n📌 Информация о 🇺🇦 ps-ua парсере:\n" + make_run_text(ps_ua_data)
  end

  def report_games
    games = manager.report_games
    <<~MESSAGE
      📌 🇹🇷Турецкие игры:
        ✅ Активные: #{games.where(deleted: 0, published: 1).where(parent: [settings['parent_ps5'], settings['parent_ps4']]).size}
        ✅ Удаленные: #{games.where(deleted: 1).where(parent: [settings['parent_ps5'], settings['parent_ps4']]).size}
        ✅ Снятые с публикации: #{games.where(published: 0).where(parent: [settings['parent_ps5'], settings['parent_ps4']]).size}
      
      📌 🇺🇦Украинские игры:
        ✅ Активные: #{games.where(deleted: 0, published: 1).where(parent: [21, 22]).size}
        ✅ Удаленные: #{games.where(deleted: 1).where(parent: [21, 22]).size}
        ✅ Снятые с публикации: #{games.where(published: 0).where(parent: [21, 22]).size}

      📌 🇮🇳Индийские игры:
        ✅ Активные: #{games.where(deleted: 0, published: 1).where(parent: [24, 25]).size}
        ✅ Удаленные: #{games.where(deleted: 1).where(parent: [24, 25]).size}
        ✅ Снятые с публикации: #{games.where(published: 0).where(parent: [24, 25]).size}
    MESSAGE
  end

  private

  attr_reader :manager

  def make_run_text(data)
    <<~MESSAGE
      ✅ Hомер запуска: #{data.id}
      ✅ Статус: #{data.status}
      ✅ Дата запуска: #{(data.created_at + 3.hours).strftime("%e %B %Y %T")}
      ✅ Дата #{data.status}: #{(data.updated_at + 3.hours).strftime("%e %B %Y %T")}
    MESSAGE
  end
end