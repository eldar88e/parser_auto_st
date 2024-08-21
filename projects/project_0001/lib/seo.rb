class Seo
  def initialize(domain, name)
    @domain = domain
    @name   = name
  end

  def title
    seo[0]
  end

  def description
    seo[1]
  end

  private

  def seo
    @seo ||= send(@domain, @name)
  end

  def open_ps
    title = "#{@name} - Купить в Open-PS.Store"
    desc  = "Ищите как играть в #{@name} из России? Наш сервис помогает с покупкой игр для PS4 и PS5. Без VPN и блокировок"
    [title, desc]
  end

  def ps_try
    title = "Купить #{@name} для PlayStation в России"
    desc  = "Помогаем с покупкой #{@name} для PlayStation. Сервис PS-TRY.RU - Игры и PS Plus для пользователей из России"
    [title, desc]
  end

  def reloc
    title = "Купить #{@name} в Релок.Store - твой друг в турецком PS Store"
    desc  = "Купить #{@name} в каталоге игр для PlayStation. Вы хотите купить #{@name} - Заходите на Reloc.Store >> "\
      "Более 3000 игр из PS Store в каталоге!"
    [title, desc]
  end

  def ps_store
    title = "#{@name} купить в ПС-СТОР.РФ / Игры для PS4 и PS5"
    desc  = "Купить игру #{@name} по выгодной цене. Аккаунт в подарок! Вы искали игру #{@name} где купить? - "\
      "Более 3000 игр в каталоге на нашем сайте ПС-СТОР.РФ >> 100% гарантия от блокировок"
    [title, desc]
  end
end
