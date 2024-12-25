module Hamster
  class Translator
    def translate_type(type_raw)
      case type_raw
      when 'Full Game', 'Game'
        'Игра'
      when 'Bundle'
        'Комплект'
      when 'VR Game'
        'VR игра'
      when 'PSN Game'
        'PSN игра'
      when 'Game Content'
        'Контент'
      else
        type_raw
      end
    end

    def translate_genre(text)
      result = genres[text.downcase]
      return result if result

      notify "Genre without translation – #{text}"
      text
    end

    private

    def genres
      { 'arcade' => 'Аркада',
        'action' => 'Экшен',
        "adventure" => "Приключение",
        "casual" => "Казуальная",
        "driving/racing" => "Гонки",
        "educational" => "Образовательная",
        "family" => "Семейная",
        "fighting" => "Файтинг",
        "fitness" => "Фитнес",
        "horror" => "Хоррор",
        "music/rhythm" => "Музыкальная/Ритм",
        "party" => "Пати",
        "puzzle" => "Головоломка",
        "quiz" => "Викторина",
        "role playing games" => "Ролевая игра",
        "shooter" => "Шутер",
        "simulation" => "Имитация",
        "simulator" => "Симулятор",
        "sport" => "Спортивная",
        "strategy" => "Стратегия",
        'unique' => 'Уникальные',
        'adult' => 'Для взрослых',
        'brain training' => 'Тренировка мозга'
      }
    end

    def notify(message, color=:green, method_=:info)
      Hamster.logger.send(method_, message)
      Hamster.report message: message
      puts color.nil? ? message : message.send(color) if @debug
    end
  end
end