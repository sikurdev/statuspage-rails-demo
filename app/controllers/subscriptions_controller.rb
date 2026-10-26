class SubscriptionsController < ApplicationController
  before_action :set_subscriber, except: :create
  rate_limit to: 10, within: 1.minute, only: :create

  # Always answers with the same message for new and existing addresses so the
  # form cannot be used to discover who is subscribed.
  def create
    @subscriber = Subscriber.find_or_initialize_by(email: Subscriber.normalize_value_for(:email, subscriber_params[:email]))

    if @subscriber.save
      SubscriptionMailer.with(subscriber: @subscriber).confirmation.deliver_later unless @subscriber.confirmed?
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path, notice: "Check your inbox to confirm your subscription." }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def confirm
    @subscriber.confirm!
    redirect_to root_path, notice: "Subscription confirmed. You'll get an email when an incident opens or resolves."
  end

  def unsubscribe
  end

  def destroy
    @subscriber.destroy!
    redirect_to root_path, notice: "You have been unsubscribed."
  end

  private
    def set_subscriber
      @subscriber = Subscriber.find_by!(token: params[:token])
    end

    def subscriber_params
      params.expect(subscriber: [ :email ])
    end
end
