# frozen_string_literal: true

module RapiTapir
  module Server
    # Path matching utility for HTTP routes
    # Matches request paths against endpoint path patterns with parameter extraction
    class PathMatcher
      attr_reader :path_pattern, :param_names

      def initialize(path_pattern)
        @path_pattern = path_pattern
        @param_names = extract_param_names(path_pattern)
        @regex = build_regex(path_pattern)
      end

      def match(path)
        match_data = @regex.match(path)
        return nil unless match_data

        params = {}
        @param_names.each_with_index do |param_name, index|
          params[param_name.to_sym] = match_data[index + 1]
        end

        params
      end

      def matches?(path)
        @regex.match?(path)
      end

      private

      def extract_param_names(pattern)
        pattern.scan(/:(\w+)/).flatten
      end

      def build_regex(pattern)
        # Convert "/users/:id/posts/:post_id" to /^\/users\/([^\/]+)\/posts\/([^\/]+)$/
        regex_pattern = pattern.gsub(/:(\w+)/, '([^/]+)')
        Regexp.new("^#{regex_pattern}$")
      end
    end
  end
end
