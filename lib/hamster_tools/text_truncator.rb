class TextTruncator
  def initialize(options = {})
    @max  = options[:max]
    @text = options[:text]
    @dots = options[:dots]
  end

  def self.call(options = {})
    new(options).truncate
  end

  def truncate
    return if @text.blank?

    select_shortest_sentence
    cut_sentence if @text.size > @max
    @text.sub!(/:$/, '...') if @dots
    @text
  end

  private

  def select_shortest_sentence
    ids = []
    if @text.size > @max
      sentence_ends = @text[@max / 2..@max + 50].scan(/\w{4,}[.]|\w{4,}[?]|\w{4,}!/)
      sentence_ends.each do |sentence_end|
        ids << ((@text.index(sentence_end) || 0) + sentence_end.size)
      end
      text_new_length = ids.select { |id| id <= @max }.max
      @text = @text[0, text_new_length] unless text_new_length.nil?
    end
  end

  def cut_sentence
    @text = @text[0, @max].strip
    @text = @text[0, @text.size - 1] while @text.scan(/\w{3,}$/)[0].nil?
  end
end
