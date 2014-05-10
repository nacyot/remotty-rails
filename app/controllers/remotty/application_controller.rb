require 'rails'

class Remotty::ApplicationController < ActionController::API
  # To resolve the following error: ActionController::UnknownFormat
  include ActionController::StrongParameters

  # To resolve the following error: undefined method `respond_to'
  # http://railscasts.com/episodes/348-the-rails-api-gem?language=ko&view=asciicast
  include ActionController::MimeResponds

  # To resolve the following error: undefined method `default_render'
  # https://github.com/rails-api/rails-api/issues/93
  include ActionController::ImplicitRender

protected

  def render_error(code = 'ERROR', message = '', status = 400)
    render json: {
      error: {
        code: code,
        message: message
      }
    }, :status => status
  end
end