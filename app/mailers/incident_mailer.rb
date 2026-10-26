class IncidentMailer < ApplicationMailer
  def status_changed
    @incident = params[:incident]
    @subscriber = params[:subscriber]
    @update = @incident.updates.first
    state = @incident.resolved? ? "Resolved" : "New incident"
    mail to: @subscriber.email, subject: "[#{state}] #{@incident.title}"
  end
end
