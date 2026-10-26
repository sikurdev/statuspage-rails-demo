class SubscriptionMailer < ApplicationMailer
  def confirmation
    @subscriber = params[:subscriber]
    mail to: @subscriber.email, subject: "Confirm your status page subscription"
  end
end
