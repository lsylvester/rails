# frozen_string_literal: true

require "action_cable/current"

module ActionCable
  class LogSubscriber < ActiveSupport::LogSubscriber
    def logger
      (Current.connection || ActionCable.server).logger
    end

    def transmit(event)
      status = "#{event.payload[:channel_class]} transmitted #{event.payload[:data].inspect.truncate(300)}"
      status += " (via #{event.payload[:via]})" if event.payload[:via]
      debug(status)
    end

    def transmit_subscription_confirmation(event)
      info "#{event.payload[:channel_class]} transmitted the subscription confirmation"
    end

    def transmit_subscription_rejection(event)
      info "#{event.payload[:channel_class]} transmitted the subscription rejection"
    end

    def broadcast(event)
      debug "[ActionCable] Broadcast to #{event.payload[:broadcasting]}: #{event.payload[:message].inspect}"
    end

    def perform_action(event)
      if !event.payload[:invalid_action]
        info "Processed #{action_signature(event.payload)} (#{event.duration.round(1)}ms)"
      else
        error "Unable to process #{action_signature(event.payload)}"
      end
    end

    private

      def action_signature(channel_class:, action:, data:, **_)
        "#{channel_class}##{action}".dup.tap do |signature|
          if (arguments = data.except("action")).any?
            signature << "(#{arguments.inspect})"
          end
        end
      end
  end
end

ActionCable::LogSubscriber.attach_to :action_cable
