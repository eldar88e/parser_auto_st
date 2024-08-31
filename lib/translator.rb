module Hamster
  class Translator
    def translate_type(type_raw)
      case type_raw
      when 'Full Game'
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
        notify "Неизвестный тип игры для Индии - #{type_raw}"
        nil
      end
    end

    def translate_genre(text)
      result = genres[text.downcase]
      return result if result

      notify "Unknown genre - #{text}"
      'Другое'
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
        "simulation" => "Симулятор",
        "sport" => "Спортивная",
        "strategy" => "Стратегия",
        'unique' => 'Уникальные'
      }
    end

    def notify(message, color=:green, method_=:info)
      Hamster.logger.send(method_, message)
      Hamster.report message: message
      puts color.nil? ? message : message.send(color) if @debug
    end
  end
end