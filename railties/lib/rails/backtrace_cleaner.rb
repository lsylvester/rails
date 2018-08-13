# frozen_string_literal: true

require "active_support/backtrace_cleaner"

module Rails
  class BacktraceCleaner < ActiveSupport::BacktraceCleaner
    APP_DIRS_PATTERN = /^\/?(app|config|lib|test|\(\w*\))/
    RENDER_TEMPLATE_PATTERN = /.*_\w+_{2,3}\d+_\d+/
    EMPTY_STRING = "".freeze
    SLASH        = "/".freeze
    DOT_SLASH    = "./".freeze

    def initialize
      super
      @root = "#{Rails.root}/".freeze
      add_filter(:path) { |path| path.sub(@root, EMPTY_STRING) }
      add_filter(:path) { |path| path.sub(DOT_SLASH, SLASH) } # for tests
      add_filter(:label) { |label| RENDER_TEMPLATE_PATTERN.match?(label) ? nil : label }

      add_gem_filters
      add_silencer(:path) { |path| !APP_DIRS_PATTERN.match?(path) }
    end

    private
      def add_gem_filters
        gems_paths = (Gem.path | [Gem.default_dir]).map { |p| Regexp.escape(p) }
        return if gems_paths.empty?

        gems_regexp = %r{(#{gems_paths.join('|')})/gems/([^/]+)-([\w.]+)/(.*)}
        gems_result = '\2 (\3) \4'.freeze
        add_filter(:path) { |path| path.sub(gems_regexp, gems_result) }
      end
  end
end
