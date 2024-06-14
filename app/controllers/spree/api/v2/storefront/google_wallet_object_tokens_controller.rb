module Spree
  module Api
    module V2
      module Storefront
        class GoogleWalletObjectTokensController < Spree::Api::V2::ResourceController
          before_action :require_spree_current_user

          def line_item
            @line_item ||= Spree::LineItem.find(params[:line_item_id])
          end

          def create
            render json: { error: 'Context is blank' }, status: :unprocessable_entity if line_item.google_wallet.blank?

            builder = line_item.google_wallet.object_builder.new(line_item: line_item)

            render json: { token: builder.object_token }
          end
        end
      end
    end
  end
end