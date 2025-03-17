module Hamster
  class Harvester
    class JsonSaver
      def initialize(storehouse)
        @store = "#{storehouse}store/"

        FileUtils.mkdir_p @store
        @file_path = "#{@store}urls.json"
        @data      = load_data
      end

      def add_url(url, title)
        unless @data.key?(url)
          @data[url] = title
          save_data
        end
      end

      def urls
        @data
      end

      private

      def load_data
        return {} unless File.exist?(@file_path)

        JSON.parse(File.read(@file_path))
      rescue JSON::ParserError
        {}
      end

      def save_data
        File.write(@file_path, JSON.pretty_generate(@data))
      end
    end
  end
end