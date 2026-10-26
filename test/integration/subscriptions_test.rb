require "test_helper"

class SubscriptionsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "subscribe sends a confirmation email (turbo stream)" do
    assert_difference -> { Subscriber.count }, 1 do
      assert_enqueued_email_with SubscriptionMailer, :confirmation, params: ->(params) { params[:subscriber].email == "new@example.com" } do
        post subscriptions_path, params: { subscriber: { email: "New@Example.com" } }, as: :turbo_stream
      end
    end
    assert_response :success
    assert_match "Check your inbox", response.body
    assert_not Subscriber.find_by(email: "new@example.com").confirmed?
  end

  test "subscribe via plain HTML redirects with a notice" do
    post subscriptions_path, params: { subscriber: { email: "html@example.com" } }
    assert_redirected_to root_path
  end

  test "invalid email re-renders the form" do
    assert_no_difference -> { Subscriber.count } do
      post subscriptions_path, params: { subscriber: { email: "nope" } }
    end
    assert_response :unprocessable_content
    assert_select ".form-error", /Email is invalid/
  end

  test "existing confirmed email gets the same answer and no new email" do
    assert_no_enqueued_emails do
      post subscriptions_path, params: { subscriber: { email: "confirmed@example.com" } }, as: :turbo_stream
    end
    assert_match "Check your inbox", response.body
  end

  test "confirm with token" do
    subscriber = subscribers(:pending)
    get confirm_subscription_path(subscriber.token)
    assert_redirected_to root_path
    assert subscriber.reload.confirmed?
  end

  test "unknown token is a 404" do
    get confirm_subscription_path("nope")
    assert_response :not_found
  end

  test "unsubscribe" do
    subscriber = subscribers(:confirmed)
    get unsubscribe_subscription_path(subscriber.token)
    assert_response :success

    assert_difference -> { Subscriber.count }, -1 do
      delete subscription_path(subscriber.token)
    end
    assert_redirected_to root_path
  end
end
