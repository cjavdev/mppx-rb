# frozen_string_literal: true

module Mppx
  module Env
    VARIABLES = {
      realm: %w[
        FLY_APP_NAME
        HEROKU_APP_NAME
        HOST
        HOSTNAME
        MPP_REALM
        RAILWAY_PUBLIC_DOMAIN
        RENDER_EXTERNAL_HOSTNAME
        VERCEL_URL
        WEBSITE_HOSTNAME
      ].freeze,
      secret_key: %w[MPP_SECRET_KEY].freeze
    }.freeze

    DEFAULTS = {
      realm: "MPP Payment"
    }.freeze

    module_function

    def get(key)
      vars = VARIABLES[key]
      return nil unless vars

      vars.each do |name|
        value = ENV[name]
        return value if value && !value.empty?
      end

      DEFAULTS[key]
    end
  end
end
