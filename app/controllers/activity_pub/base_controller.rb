module ActivityPub
  class BaseController < ApplicationController
    allow_unauthenticated_access
    skip_before_action :verify_authenticity_token
    before_action :set_content_type_header

    private

    def set_content_type_header
      response.headers["Content-Type"] = "application/activity+json"
    end
  end
end
