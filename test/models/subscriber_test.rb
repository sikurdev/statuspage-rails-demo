require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  test "normalizes email and generates a token" do
    subscriber = Subscriber.create!(email: "  New@Example.COM ")
    assert_equal "new@example.com", subscriber.email
    assert subscriber.token.present?
    assert_not subscriber.confirmed?
  end

  test "rejects invalid and duplicate emails" do
    assert_not Subscriber.new(email: "not-an-email").valid?
    assert_not Subscriber.new(email: "CONFIRMED@example.com").valid?
  end

  test "confirm! sets confirmed_at once" do
    subscriber = subscribers(:pending)
    subscriber.confirm!
    confirmed_at = subscriber.confirmed_at
    assert subscriber.confirmed?

    travel 1.hour do
      subscriber.confirm!
      assert_equal confirmed_at, subscriber.reload.confirmed_at
    end
  end

  test "confirmed scope" do
    assert_equal [ subscribers(:confirmed) ], Subscriber.confirmed.to_a
  end
end
