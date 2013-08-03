module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'get /v1/invoices', :list_invoices
        klass.add_handler 'get /v1/invoices/upcoming', :upcoming_invoice
      end

			def upcoming_invoice(route, method_url, params, headers)
				if customers[params[:customer]]
					params.merge!({
													:amount_due => (customers[params[:customer]][:subscription][:quantity] * 100),
													:total => (customers[params[:customer]][:subscription][:quantity] * 100),
													:discount => (customers[params[:customer]][:discount] ?
																				Data.mock_discount({:coupon => customers[params[:customer]][:discount][:coupon][:id]})
																				: nil)
												})
				end
				Data.mock_invoice(params)
			end

			def list_invoices(route, method_url, params, headers)
				{
					:object => "list",
					:url => "/v1/invoices",
					:count => 1,
					:data => [Data.mock_invoice(params)]
				}
			end

      def new_invoice_item(route, method_url, params, headers)
        Data.mock_invoice(params)
      end

    end
  end
end
