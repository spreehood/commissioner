module Spree
  module Api
    module V2
      module Storefront
        class PinCodeOtpGeneratorsController < ::Spree::Api::V2::ResourceController
          before_action :validate_recaptcha, only: [:create]

          def validate_recaptcha
            return unless ENV['RECAPTCHA_TOKEN_VALIDATOR_ENABLE'] == 'yes'

            context = SpreeCmCommissioner::RecaptchaTokenValidator.call(
              token: params[:recaptcha_token],
              action: params[:recaptcha_action],
              site_key: params[:recaptcah_site_key]
            )

            return if context.success?

            render_error_payload(context.message, 400)
          end

          # :phone_number, :email, :type, :recaptcha_token, :recaptcha_action, :recaptcah_site_key
          def create
            options = otp_attrs
            options[:type] = 'SpreeCmCommissioner::PinCodeOtp'

            context = SpreeCmCommissioner::PinCodeGenerator.call(options)

            if context.success?
              render_serialized_payload(201) { serialize_resource(context.pin_code) }
            else
              render_error_payload(context.message, 400)
            end
          end

          def serialize_resource(resource)
            resource_serializer.new(
              resource
            ).serializable_hash
          end

          def resource_serializer
            SpreeCmCommissioner::V2::Storefront::PinCodeSerializer
          end

          def otp_attrs
            params.slice(:phone_number, :email)
          end
        end
      end
    end
  end
end
