# Admin credentials come from the environment only. If ADMIN_PASSWORD is not
# set the admin area stays locked (fail closed).
module AdminCredentials
  def self.username = ENV.fetch("ADMIN_USERNAME", "admin")
  def self.password = ENV["ADMIN_PASSWORD"].to_s

  def self.configured? = password.present?

  def self.valid?(user, pass)
    configured? &
      ActiveSupport::SecurityUtils.secure_compare(user.to_s, username) &
      ActiveSupport::SecurityUtils.secure_compare(pass.to_s, password)
  end
end
