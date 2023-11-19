# frozen_string_literal: true

module Hamster
  module HamsterTools
    def parse_arguments
      args = {}
      num_type = -> x { x.match(/#{x.to_f}/) ? x.to_f : x.to_i }
      ARGV.each do |arg|
        m1 = /^--?(?<key>\w+)$/.match(arg)
        m2 = /^--(?<key>\w+?)=(?<value>.*)$/.match(arg)
        if m1
          args[m1[:key]] = true
        elsif m2
          args[m2[:key]] =
            case m2[:value]
            when /^(true|false)$/
              m2[:value] == 'true'
            when /^-?\d+$/
              m2[:value].to_i
            when /^-?\d+\.?\d*$/
              m2[:value].to_f
            when /^-?\d+\.?\d*\.\.\.?-?\d+\.?\d*$/
              a, b = m2[:value].split(/\.\.\.?/)
              a    = num_type[a]
              b    = num_type[b]
              Range.new(a, b, m2[:value].match(/\.\.\./))
            when /^.*\.\.\.?.*$/
              a, b = m2[:value].split(/\.\.\.?/)
              Range.new(a, b, m2[:value].match(/\.\.\./))
            when /^\d+(?>[.]\d+)?(?>,\d+(?>[.]\d+)?)+/
              m2[:value].split(',').map { |el| num_type[el] }
            when /^:\w+$/
              m2[:value][1..-1].to_sym
            else
              m2[:value].to_s
            end
        end
      end
      @arguments = args.merge(args.transform_keys(&:to_sym))
    end
  end
end
