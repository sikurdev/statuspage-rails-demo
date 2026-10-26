require "test_helper"

class SubscriptionMailerTest < ActionMailer::TestCase
  test "confirmation contains the confirm link" do
    subscriber = subscribers(:pending)
    mail = SubscriptionMailer.with(subscriber: subscriber).confirmation

    assert_equal [ "pending@example.com" ], mail.to
    assert_match "/subscriptions/#{subscriber.token}/confirm", mail.text_part.body.to_s
  end
end

class IncidentMailerTest < ActionMailer::TestCase
  test "new incident and resolution emails" do
    subscriber = subscribers(:confirmed)

    mail = IncidentMailer.with(incident: incidents(:api_outage), subscriber: subscriber).status_changed
    assert_equal "[New incident] API is down", mail.subject
    assert_match "API failed 2 consecutive checks", mail.text_part.body.to_s
    assert_match "/subscriptions/#{subscriber.token}/unsubscribe", mail.text_part.body.to_s

    mail = IncidentMailer.with(incident: incidents(:website_past), subscriber: subscriber).status_changed
    assert_equal "[Resolved] Website is down", mail.subject
  end
end
