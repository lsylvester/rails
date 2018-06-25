#  frozen_string_literal: true

require "test_helper"
require "active_support/log_subscriber/test_helper"

class LogSubscriberTest < ActionCable::TestCase
  include ActiveSupport::LogSubscriber::TestHelper
  include ActiveSupport::Logger::Severity

  class ChatChannel < ActionCable::Channel::Base
    def get_latest
      transmit data: "latest"
    end

    def topic(data)
    end
  end

  def setup
    @old_logger = ActionCable.server.config.logger
    @connection = TestConnection.new
    @channel = ChatChannel.new @connection, "{id: 1}", id: 1
    super
    ActionCable::LogSubscriber.attach_to(:action_cable)
  end

  def teardown
    ActionCable::LogSubscriber.log_subscribers.pop
    ActionCable.server.config.instance_variable_set(:@logger, @old_logger)
  end

  def set_logger(logger)
    ActionCable.server.config.instance_variable_set(:@logger, logger)
  end

  test "transmit logging" do
    @channel.perform_action "action" => :get_latest
    assert_equal 1, @logger.logged(:debug).size
    assert_equal "LogSubscriberTest::ChatChannel transmitted {:data=>\"latest\"}", @logger.logged(:debug).last
  end

  test "transmit_subscription_confirmation logging" do
    @channel.subscribe_to_channel
    assert_equal 1, @logger.logged(:info).size
    assert_equal "LogSubscriberTest::ChatChannel transmitted the subscription confirmation",  @logger.logged(:info).last
  end

  test "transmit_subscription_rejection logging" do
    @channel.send(:transmit_subscription_rejection)
    assert_equal 1, @logger.logged(:info).size
    assert_equal "LogSubscriberTest::ChatChannel transmitted the subscription rejection",  @logger.logged(:info).last
  end

  test "broadcast logging" do
    broadcasting = "test_queue"
    message = { body: "test message" }
    @connection.server.broadcast(broadcasting, message)
    assert_equal 1, @logger.logged(:debug).size
    assert_equal "[ActionCable] Broadcast to test_queue: {:body=>\"test message\"}",  @logger.logged(:debug).last
  end

  test "perform_action logging" do
    @channel.perform_action "action" => :topic, "content" => "This is Sparta!"
    assert_equal 1, @logger.logged(:info).size
    assert_match(/Processed LogSubscriberTest::ChatChannel#topic\({"content"=>"This is Sparta!"}\) \(\d+\.\dms\)/, @logger.logged(:info).last)
  end

  test "perform_action with invalid action logging" do
    @channel.perform_action "action" => :bad
    assert_equal 1, @logger.logged(:error).size
    assert_equal "Unable to process LogSubscriberTest::ChatChannel#bad", @logger.logged(:error).last
  end

  test "use the connection logger when there is a current connection" do
    ActionCable::Current.set(connection: @connection) do
      assert_equal @connection.logger, ActionCable::LogSubscriber.subscribers.last.logger
    end
  end

  test "use the server logger when there is no connection" do
    assert_equal ActionCable.server.logger, ActionCable::LogSubscriber.subscribers.last.logger
  end
end
