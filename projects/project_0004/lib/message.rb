require_relative 'model_manager'

class Message
  def initialize
    @manager = ModelManager.new
  end

  def commands
    <<~MESSAGE
    Доступные команды для бота:
      - run_last – для просмотра информации о последнем запуске парсера
      - report_games – отчет о количестве активных, не опубликованых и удаленных играх
    MESSAGE
  end

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

  private

  attr_reader :manager

end