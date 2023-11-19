# frozen_string_literal: true

module Hamster
  
  # The base class for custom scraping classes
  class Scraper < Hamster::Harvester
    def initialize(*_)
      super
      #update_proxies
    end

    private
    
    # Wraps Hamster.connect_to and add proxies
    # @param [Array] arguments
    # @option [String] url Target url that we need to connect
    # @option [Hash] headers List of HTTP headers
    # @option [String] req_body Request body
    # @option [String] proxy Proxy address. If scheme wasn't defined uses it as SOCKS5-proxy
    # @option [String] cookies String with cookies
    # @option [ProxyFilter] proxy_filter ProxyFilter instance
    # @option [Integer] open_timeout Timeout of waiting the source will be opened
    # @option [Integer] timeout Timeout of waiting the source will be downloaded
    # @option [Symbol] method Using HTTP-method. It can be :post or :get (default)
    # @return [Faraday::Response, Nil] the source response or nil unless response given
    def connect_to(*arguments, &block)
      #adding_proxy = { proxy: proxies }
      
      #if arguments.last.is_a?(Hash)
      #  arguments.last.merge!(adding_proxy) unless arguments.last[:proxy]
      #elsif arguments.size == 1
      #  arguments << adding_proxy
      #end
      
      Hamster.connect_to(*arguments, &block)
    end
    
    # @return [Array] contains rows from table `paid_proxies`
    def proxies
      @_proxies_
    end
    
    # Updates an instance variable @_proxies_
    def update_proxies
      @_proxies_ = PaidProxy.all
    end
    
    # @return [Array] of given file rows
    def list_from_file(file_name)
      File.exist?(file_name) ? File.readlines(file_name).map { |el| el.nil? || el.empty? ? nil : el.strip }.compact.uniq.sort : []
    end
    
    # Wraps the Hamster.log
    def log(text, color = nil, verbose = false)
      Hamster.log(text, color, verbose)
    end

  end
end
