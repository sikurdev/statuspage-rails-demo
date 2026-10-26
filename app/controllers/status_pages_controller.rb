class StatusPagesController < ApplicationController
  def show
    @status_page = StatusPage.new
    @subscriber = Subscriber.new
  end
end
