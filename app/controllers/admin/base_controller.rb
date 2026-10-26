module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :authenticate_admin!

    private
      def authenticate_admin!
        unless AdminCredentials.configured?
          return render plain: "Admin is disabled: set ADMIN_PASSWORD to enable it.", status: :service_unavailable
        end

        authenticate_or_request_with_http_basic("Admin") do |user, password|
          AdminCredentials.valid?(user, password)
        end
      end
  end
end
