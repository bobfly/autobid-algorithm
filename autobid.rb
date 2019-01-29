require 'bigdecimal'
require 'date'
require 'active_support/time'

class AutoBidService
  def initialize
  end

  #based by my talk with Philippe
  # we have scenario
  # Reverse Auction with capacity 10.000, start price 10.00 and step 1
  # User 1 creates offer 1 with qty 4.000 and min_price: 


  # until capacity is fullfiled put everything inside contigent with start_price
  # once capacity is fullfiled we need to autobid
  # First check is there any offer that will match qty and check lowest price
  # when you check that if lower price until <=
  # When someone else creates new offer with qty that will fit inside auction capacity
  # we need to set price in order to get offers with status 'inside contigent', 
  # get their current_price (minimum) and reduce offer price by one step
  # When someone else creates new offer with qty that will exceed capacity
  # we need to fight against all offers that have status 'inside contigent',
  # and where min price is greater or equal to current offer



  # scenario 1
  # winner should be offer two with price 29 and first offer should remain at 30
  # PASS
  def scenario_one
    @offers = [
        {id: 1, price: 50, min_price: 30, delivery_quantity: 7000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 50, min_price: 3, delivery_quantity: 5000, status: "outside_contigent", user_updated_at: (DateTime.now + 3.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 2
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario 2
  # winner should be offer 1 with price 25
  # PASS
  def scenario_two  
    @offers = [
        {id: 1, price: 50, min_price: 25, delivery_quantity: 7000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 50, min_price: 26, delivery_quantity: 8000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 2
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario 3
  # offer 1,2 are winners with price 8
  # PASS
  def scenario_three
    @offers = [
        {id: 1, price: 10, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 10, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 10, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 3
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  # scenario four
  # offers 1,2,4 are winners with price 9
  #
  def scenario_four
    @offers = [
        {id: 1, price: 9, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 9, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 9, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)},
        {id: 4, price: 9, min_price: 3, delivery_quantity: 1950, status: "outside_contigent", user_updated_at: (DateTime.now + 7.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 4
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  def scenario_five
    @offers = [
        {id: 1, price: 9, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 9, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 9, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)},
        {id: 4, price: 8, min_price: 3, delivery_quantity: 1950, status: "inside_contigent", user_updated_at: (DateTime.now + 7.minutes)},
        {id: 5, price: 8, min_price: 2, delivery_quantity: 50, status: "outside_contigent", user_updated_at: (DateTime.now + 8.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 5
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  def print
    @offers.sort_by{|o| o[:user_updated_at]}.sort_by{|o| o[:status]}.sort_by{|o| o[:price]}.each do |o|
      p "id: #{o[:id]}, price: #{o[:price].to_s}, min_price: #{o[:min_price]}, delivery_quantity: #{o[:delivery_quantity]}, status: #{o[:status]}, user_updated_at: #{o[:user_updated_at].strftime("%-d.%-m.%Y %-l:%M%p")}"  
    end
  end

  def check_capacity
    @offered_capacity = @offers.select{|o| o[:id] != @current_offer[:id] && o[:status] == "inside_contigent"}.map{|o| o[:delivery_quantity]}.sum
  end

  def get_lowest_offer
    @lowest_offer = @offers.select{|o| o[:id] != @current_offer[:id]}.sort_by{|o| o[:min_price]}.first
  end

  def can_underbid(offer, bid_to_underbid)
    if not bid_to_underbid
      false
    else
      offer[:price] > offer[:min_price] && offer[:min_price] < bid_to_underbid[:price] && bid_to_underbid[:price] - @step >= offer[:min_price]
    end
  end



  def autobid
    current_offer = @current_offer
    @offers = @offers.sort_by{|o| o[:user_updated_at]}
    # get all placed offers and divide them into groups
    inside_contigent = @offers.select{|o| o[:status] == "inside_contigent"}
    outside_contigent = @offers.select{|o| o[:status] == "outside_contigent"}
    kwh_sum = 0
    has_inside_contingent = inside_contigent.size > 0
    has_outside_contingent = outside_contigent.size > 0

    unless has_outside_contingent
      # if there are no bids stop
      return #break
    else
      # what is current state of capacity and delivery
      kwh_sum = inside_contigent.map{|o| o[:delivery_quantity]}.sum
      if kwh_sum + current_offer[:delivery_quantity] > @capacity
        # is there an offer that have same capacity
        if offer_with_same_quantity?(current_offer[:id], current_offer[:delivery_quantity])
          # can I compeet them with price?
          # if not set my minimum price
          if lowest_min_price?(current_offer[:id]) <= current_offer[:min_price] 
            current_offer[:price] = current_offer[:min_price]
            @offers.select{|o| o[:id] != current_offer[:id] && o[:status] == "inside_contigent"}.each do |o|
              # if offer inside_contigent can handle min_price of current_offer set them
              if o[:min_price] <= current_offer[:min_price]
                o[:price] = current_offer[:min_price]
              else
                p "we should be kicked_out (outside contigent)"
              end
            end
          end
        else
          if lowest_min_price?(current_offer[:id]) <= current_offer[:min_price]
            current_offer[:price] = current_offer[:min_price]
            @offers.select{|o| o[:id] != current_offer[:id] && o[:status] == "inside_contigent"}.each do |o|
              if o[:min_price] <= current_offer[:min_price]
                o[:price] = current_offer[:min_price] - @step
              else
                p "we should be kicked_out (outside contigent)"
              end
            end
          elsif lowest_min_price?(current_offer[:id]) > current_offer[:min_price]
            @offers.select{|o| o[:id] != current_offer[:id] && o[:status] == "inside_contigent" && o[:min_price] > current_offer[:min_price]}.each do |o|
              o[:price] = o[:min_price]
            end
            current_offer[:price] = get_my_price(current_offer[:id])
          end
        end
      else
        if offer_can_fit?(current_offer[:delivery_quantity], current_offer[:id])
          # highest offer inside contigent - step
          current_offer[:price] = get_my_price(current_offer[:id])
        else
          p "compeet with everyone inside_contigent"
        end
      end
      
    end
  end

  def offer_with_same_quantity?(current_offer_id, quantity)
    @offers.select{|o| o[:id] != current_offer_id && o[:status] == "inside_contigent" && o[:delivery_quantity] == quantity}.size > 0
  end

  def lowest_min_price?(current_offer_id)
    @offers.select{|o| o[:id] != current_offer_id && o[:status] == "inside_contigent"}.sort_by{|o| -o[:min_price]}.first[:min_price]
  end

  def offer_can_fit?(delivery_quantity, current_offer_id)
    (@offers.select{|o| o[:id] != current_offer_id && o[:status] == "inside_contigent"}.map{|o| o[:delivery_quantity]}.sum + delivery_quantity) <= @capacity
  end

  def get_my_price(current_offer_id)
    @offers.select{|o| o[:id] != current_offer_id && o[:status] == "inside_contigent"}.sort_by{|o| o[:price]}.first[:price] - @step
  end

  def ranking
    @offers = @offers.sort_by{|o| o[:price]}
    kwh_sum = 0
    inside_contingent = []
    outside_contingent = []

    @offers.each do |o|
      kwh_sum += o[:delivery_quantity]
      is_inside_contingent = kwh_sum <= @capacity
      
      if is_inside_contingent
        o[:status] = "inside_contigent"
      else
        o[:status] = "outside_contigent"
      end
    end
  end
end



@s = AutoBidService.new

#@s.scenario_one

#@s.scenario_two

#@s.scenario_three

#@s.scenario_four

@s.scenario_five

@s.autobid
@s.ranking
#@s.set_inside_to_maximum


@s.print


