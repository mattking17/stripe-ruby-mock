module StripeMock
  module RequestHandlers
    module Invoices

      def Invoices.included(klass)
        klass.add_handler 'get /v1/invoices/upcoming', :upcoming_invoice
      end

			def upcoming_invoice(route, method_url, params, headers)
				return Data.mock_invoice(params)
			end

      def new_invoice_item(route, method_url, params, headers)
        Data.mock_invoice(params)
      end

    end
  end
end
