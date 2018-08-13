# frozen_string_literal: true

module ActiveSupport
  # Backtraces often include many lines that are not relevant for the context
  # under review. This makes it hard to find the signal amongst the backtrace
  # noise, and adds debugging time. With a BacktraceCleaner, filters and
  # silencers are used to remove the noisy lines, so that only the most relevant
  # lines remain.
  #
  # Filters are used to modify lines of data, while silencers are used to remove
  # lines entirely. The typical filter use case is to remove lengthy path
  # information from the start of each line, and view file paths relevant to the
  # app directory instead of the file system root. The typical silencer use case
  # is to exclude the output of a noisy library from the backtrace, so that you
  # can focus on the rest.
  #
  #   bc = ActiveSupport::BacktraceCleaner.new
  #   bc.add_filter(:path)   { |path| path.gsub(Rails.root.to_s, '') } # strip the Rails.root prefix
  #   bc.add_silencer(:path) { |path| path =~ /puma|rubygems/ } # skip any lines from puma or rubygems
  #   bc.clean(exception.backtrace) # perform the cleanup
  #
  # Each line of data is comprised of a `path`, `lineno` and `label`. A filter
  # or silencer can target a particular part of the line by passing it in add the
  # first argument to `add_filter` or `add_silencer`. If no argument is provided,
  # then the filter or silencer will act on the line as a whole.
  #
  # To reconfigure an existing BacktraceCleaner (like the default one in Rails)
  # and show as much data as possible, you can always call
  # <tt>BacktraceCleaner#remove_silencers!</tt>, which will restore the
  # backtrace to a pristine state. If you need to reconfigure an existing
  # BacktraceCleaner so that it does not filter or modify the paths of any lines
  # of the backtrace, you can call <tt>BacktraceCleaner#remove_filters!</tt>
  # These two methods will give you a completely untouched backtrace.
  #
  # Inspired by the Quiet Backtrace gem by thoughtbot.
  class BacktraceCleaner
    def initialize
      @silencers = Hash.new { |h, k| h[k] = [] }
      @filters = Hash.new { |h, k| h[k] = [] }
    end

    # Returns the backtrace after all filters and silencers have been run
    # against it. Filters run first, then silencers.
    def clean(backtrace, kind = :silent)
      backtrace = backtrace.map do |line|
        Location.new(*line.match(/^([^:]+)(?::(\d+))?(?::in `(.*?)')?/).captures)
      end

      clean_locations(backtrace, kind).map(&:to_s)
    end
    alias :filter :clean

    # Similar to `clean` but accepts an array of `Thread::Backtrace::Location` objects
    # from `backtrace_locations` or `caller_locations`. Returns an array of custom
    # location objects which expose `path`, `lineno` and `label` methods.
    def clean_locations(backtrace, kind = :silent)
      backtrace = backtrace.map { |location| Location.new(location.path, location.lineno, location.label) }

      filtered = filter(backtrace)

      case kind
      when :silent
        silence(filtered)
      when :noise
        noise(filtered)
      else
        filtered
      end
    end
    alias :filter_locations :clean_locations


    # Adds a filter from the block provided. If a type of `:path`, `:lineno` or
    # `:label` is provided then that segment of each line in the backtrace will be
    # mapped against this filter. Otherwise, if no type is provided, then each
    # line in the backtrace will be mapped against this filter.
    #
    #   # Will turn "/my/rails/root/app/models/person.rb" into "/app/models/person.rb"
    #   backtrace_cleaner.add_filter(:path) { |path| path.gsub(Rails.root, '') }
    def add_filter(type = :formatted_string, &block)
      @filters[type] << block
    end

    # Adds a silencer from the block provided. If a type of `:path`, `:lineno` or
    # `:label` is provided then that part of the line is passed into block for
    # each line. Otherwise, if no type is specificed, then each line is passed
    # into the block. If the silencer returns +true+, the line will be excluded
    # from the clean backtrace.
    #
    #   # Will reject all lines that include the word "puma" in the path, like
    #   # "/gems/puma/server.rb" or "/app/my_puma_server/rb"
    #   backtrace_cleaner.add_silencer(:path) { |path| path =~ /puma/ }
    def add_silencer(type = :formatted_string, &block)
      @silencers[type] << block
    end

    # Removes all silencers, but leaves in the filters. Useful if your
    # context of debugging suddenly expands as you suspect a bug in one of
    # the libraries you use.
    def remove_silencers!
      @silencers.clear
    end

    # Removes all filters, but leaves in the silencers. Useful if you suddenly
    # need to see entire filepaths in the backtrace that you had already
    # filtered out.
    def remove_filters!
      @filters.clear
    end

    Location = Struct.new(:path, :lineno, :label, :formatted_string) do # :nodoc:
      def to_s
        formatted_string
      end

      def formatted_string
        self[:formatted_string] ||= "#{path}#{lineno ? ":#{lineno}" : ""}#{label ? ":in `#{label}'" : ""}"
      end
    end

    private

      def filter(backtrace)
        Location.members.each do |type|
          @filters[type].each do |filter|
            backtrace.each do |location|
              location[type] = filter.call(location.send(type))
            end
          end
        end

        backtrace
      end

      def silence(backtrace)
        Location.members.each do |type|
          @silencers[type].each do |silencer|
            backtrace = backtrace.reject { |location| silencer.call(location.send(type)) }
          end
        end

        backtrace
      end

      def noise(backtrace)
        backtrace - silence(backtrace)
      end
  end
end
