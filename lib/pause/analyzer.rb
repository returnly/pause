require 'pause/helper/timing'

module Pause
  class Analyzer
    include Pause::Helper::Timing

    def check(action)
      timestamp = period_marker(Pause.config.resolution, Time.now.to_i)
      set = adapter.key_history(action.scope, action.identifier)
      action.checks.each do |period_check|
        start_time = timestamp - period_check.period_seconds
        set.reverse.inject(0) do |sum, element|
          break if element.ts < start_time
          sum += element.count
          if sum >= period_check.max_allowed
            adapter.rate_limit!(action.scope, action.identifier, period_check.block_ttl)
            # Note that Time.now is different from period_marker(resolution, Time.now), which
            # rounds down to the nearest (resolution) seconds
            return Pause::RateLimitedEvent.new(action, period_check, sum, Time.now.to_i)
          end
          sum
        end
      end
      nil
    end

    private

    def adapter
      Pause.adapter
    end
  end
end
