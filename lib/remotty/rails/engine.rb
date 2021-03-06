require 'rails'
require 'rack/cors'
require 'active_model/serializer'
require 'active_model/array_serializer'

module Remotty::Rails
  # 기본 설정
  #
  # * serializer
  #   * root key를 사용하지 않음
  # * wrap parameters
  #   * enable for json
  # * paperclip
  #   * url => '/system/:class/:attachment/:id_partition/:style/:hash.:extension'
  #   * default_url => nil (angular에서 처리)
  # * Devise
  #   * skip session storage
  #   * use custom view
  #   * return json error occur
  #   * add token based authentication strategy
  # * CORS
  #   * allow all
  # * Rails middleware
  #   * Rack::Session::Pool
  #   * ActionDispatch::Session::CookieStore, :cookie_only => false, :defer => true
  #   * ActionDispatch::Flash
  #
  class Engine < ::Rails::Engine
    initializer '0.remotty.rails.configuration' do |app|
      # active serializer
      ActiveModel::Serializer.root = false
      ActiveModel::ArraySerializer.root = false

      ActiveSupport.on_load(:action_controller) do
        # wrap parameters
        include ActionController::ParamsWrapper
        wrap_parameters format: [:json] if respond_to?(:wrap_parameters)

        # cancan
        include CanCan::ControllerAdditions
        # authority 403 forbidden
        rescue_from CanCan::AccessDenied do |exception|
          render_error 'FORBIDDEN',
                       exception.message,
                       :forbidden
        end
      end

      # paperclip
      Paperclip::Attachment.default_options.update({
                                                     :url => '/system/:class/:attachment/:id_partition/:style/:hash.:extension',
                                                     :default_url => ''
                                                   })

      # Devise
      Devise.setup do |config|
        config.skip_session_storage = [:http_auth, :token_header_auth, :params_auth]
        config.scoped_views = true
        config.warden do |manager|
          manager.failure_app = Remotty::Rails::Authentication::JsonAuthFailure
          manager.strategies.add :token_header_authenticable, Remotty::Rails::Authentication::Strategies::TokenHeaderAuthenticable
          manager.default_strategies(:scope => :user).unshift :token_header_authenticable
        end
      end

      # CORS
      ::Rails.application.config.middleware.use Rack::Cors do
        allow do
          origins "*"
          resource "*", :headers => :any, :methods => [:get, :post, :delete, :put, :patch, :options]
        end
      end

      # session for oauth/devise (no cookie)
      ::Rails.application.config.middleware.use Rack::Session::Pool
      ::Rails.application.config.middleware.use ActionDispatch::Session::CookieStore, :cookie_only => false, :defer => true
      ::Rails.application.config.middleware.use ActionDispatch::Flash
    end

  end
end
