module StripeMock
  module RequestHandlers
    module Coupons

      def Coupons.included(klass)
        klass.add_handler 'get /v1/coupons', :list_coupons
        klass.add_handler 'post /v1/coupons', :create_coupon
			end

      def list_coupons(route, method_url, params, headers)
				coupons.values
			end

      def create_coupon(route, method_url, params, headers)
				coupons[ params[:id] ] = Data.mock_coupon(params)
			end

		end
	end
end
