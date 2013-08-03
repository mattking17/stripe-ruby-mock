module StripeMock
  module RequestHandlers
    module Customers

      def Customers.included(klass)
        klass.add_handler 'post /v1/customers',                     :new_customer
        klass.add_handler 'post /v1/customers/(.*)/subscription',   :update_subscription
        klass.add_handler 'delete /v1/customers/(.*)/discount',     :delete_discount
        klass.add_handler 'delete /v1/customers/(.*)/subscription', :cancel_subscription
        klass.add_handler 'post /v1/customers/(.*)',                :update_customer
        klass.add_handler 'get /v1/customers/(.*)',                 :get_customer
        klass.add_handler 'get /v1/customers',                      :list_customers
      end

      def new_customer(route, method_url, params, headers)
        params[:id] ||= new_id('cus')
        cards = []
        if params[:card]
          cards << get_card_by_token(params.delete(:card))
          params[:default_card] = cards.first[:id]
        end
        customers[ params[:id] ] = Data.mock_customer(cards, params)

				if params[:plan] and plan = plans[ params[:plan] ]
					customers[ params[:id] ][:subscription] = Data.mock_subscription id: new_id('su'), plan: plan, customer: params[:id]
				end
				customers[ params[:id] ]
      end

      def update_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[params[:_captures][0]]
        assert_existance :customer, params[:_captures][0], customer

        plan = plans[ params[:plan] ]
        assert_existance :plan, params[:plan], plan

        # Ensure customer has card to charge if plan has no trial and is not free
        if customer[:default_card].nil? && plan[:trial_period_days].nil? && plan[:amount] != 0
          raise Stripe::InvalidRequestError.new('You must supply a valid card', nil, 400)
        end

        sub = Data.mock_subscription id: new_id('su'), plan: plan, customer: params[:_captures][0], quantity: params[:quantity]
        customer[:subscription] = sub
				if params[:trial_end] == 'now'
					customer[:subscription][:status] = 'active'
				end
				
				if params[:coupon]
					customer[:discount] = Data.mock_discount({:coupon => params[:coupon]})
				end

				customer[:subscription]
      end

      def cancel_subscription(route, method_url, params, headers)
        route =~ method_url

        customer = customers[params[:_captures][0]]
        assert_existance :customer, params[:_captures][0], customer

        sub = customer[:subscription]
        assert_existance nil, nil, sub, "No active subscription for customer: #{params[:_captures][0]}"

        customer[:subscription] = nil

        plan = plans[ sub[:plan][:id] ]
        assert_existance :plan, params[:plan], plan

				sub[:status] = 'canceled'
        Data.mock_delete_subscription(sub)
      end

      def update_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, params[:_captures][0], customers[params[:_captures][0]]

        card_id = new_id('cc') if params.delete(:card)
        cus = customers[params[:_captures][0]] ||= Data.mock_customer([], :id => params[:_captures][0])
        cus.merge!(params)

        if card_id
          new_card = Data.mock_card(id: card_id, customer: cus[:id])

          if cus[:cards][:count] == 0
            cus[:cards][:count] += 1
          else
            cus[:cards][:data].delete_if {|card| card[:id] == cus[:default_card]}
          end
          cus[:cards][:data] << new_card
          cus[:default_card] = new_card[:id]
					cus[:active_card] = new_card
        end

        cus
      end

      def get_customer(route, method_url, params, headers)
        route =~ method_url
        assert_existance :customer, params[:_captures][0], customers[params[:_captures][0]]
        customers[params[:_captures][0]] ||= Data.mock_customer([], :id => params[:_captures][0])
      end

      def list_customers(route, method_url, params, headers)
        customers.values
      end
			
			def delete_discount(route, method_url, params, headers)
        customer = customers[params[:_captures][0]]
        assert_existance :customer, params[:_captures][0], customer

				if customer[:discount]
					customer.delete(:discount)
				end
			end

    end
  end
end
