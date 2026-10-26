class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "status@example.com") }
  helper ApplicationHelper
  layout "mailer"
end
