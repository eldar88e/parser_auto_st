# frozen_string_literal: true

module Hamster
  module HamsterTools
    
    # assembles URI from passed parts of an URI.
    # @param [Hash] hash the options to assemble an URI with
    # @option hash [String] :scheme Scheme part of an URI, 'http://' by default, optional
    # @option hash [String] :host Domain part of an URI, required
    # @option hash [String] :path Path part of an URI, optional
    # @option hash [String] :query HTTP-query part of an URI, optional
    # @return [String] contains assembled URI
    def assemble_uri(**hash)
      raise 'parameter :host is required for method assemble_uri' unless hash[:host]
      
      scheme = "#{hash[:scheme].gsub(%r{(://)$}, '') || 'http'}://"
      host   = hash[:host].gsub(%r{/*$}, '')
      path   = "/#{hash[:path]}/".squeeze('/') || ''
      query  = hash[:query] ? "/?#{hash[:query].map { |k, v| "#{k.to_s}=#{v}" }.join('&')}" : ''
      scheme + (host + path + query).squeeze('/')
    end
  end
end
