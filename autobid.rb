require 'bigdecimal'
require 'date'
require 'active_support/time'

class AutoBidService
  def initialize
  end

  #based by our talk

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
        {id: 2, price: 50, min_price: 26, delivery_quantity: 15000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)}
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
        {id: 1, price: 10, min_price: 4, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: DateTime.now},
        {id: 2, price: 10, min_price: 6, delivery_quantity: 4000, status: "inside_contigent", user_updated_at: (DateTime.now + 3.minutes)},
        {id: 3, price: 10, min_price: 9, delivery_quantity: 4000, status: "outside_contigent", user_updated_at: (DateTime.now + 5.minutes)},
        {id: 4, price: 10, min_price: 3, delivery_quantity: 1900, status: "outside_contigent", user_updated_at: (DateTime.now + 7.minutes)}
        ]
    @step = 1
    @capacity = 10000
    @start_price = 50.0
    @current_offer_id = 4
    @current_offer = @offers.find{ |o| o[:id] == @current_offer_id}
  end

  def print
    @offers.sort_by{|o| o[:user_updated_at]}.sort_by{|o| o[:status]}.each do |o|
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
    @offers = @offers.sort_by{|o| o[:user_updated_at]}
    # get all placed offers and divide them into groups
    inside_contigent = @offers.select{|o| o[:status] == "inside_contigent"}
    outside_contigent = @offers.select{|o| o[:status] == "outside_contigent"}

    has_inside_contingent = inside_contigent.size > 0
    has_outside_contingent = outside_contigent.size > 0

    unless has_outside_contingent
      # if there are no bids stop
      return #break
    else
      if has_inside_contingent
        # how low can go inside_contigent bids based by outside contigent min_price
        minimum_outside_contigent = outside_contigent.first[:min_price]
        maximum_inside_contigent = inside_contigent.sort_by{|o| -o[:min_price]}.first[:min_price]
        inside_contigent.each do |o|
          if o[:min_price] >= minimum_outside_contigent
            o[:price] = o[:min_price]
          else
            if (minimum_outside_contigent - @step) < o[:min_price]
              o[:price] = o[:min_price]
            else
              o[:price] = maximum_inside_contigent #(minimum_outside_contigent - @step)
            end
          end
        end
        highest_bid_inside = inside_contigent.sort_by{|o| -o[:price]}.first
      else
        highest_bid_inside = nil
      end

      outside_contigent.each do |offer|
        if highest_bid_inside
          bid_to_underbid = highest_bid_inside
        else
          bid_to_underbid = outside_contigent.first
        end
        unless bid_to_underbid.nil? and offer != bid_to_underbid
          if can_underbid(offer, bid_to_underbid) 
            # we need to determine is this going to increase capacity value
            # if not set price like highest bids
            # else go to - step
            if i_am_changer?(@current_offer)
              offer[:price] = bid_to_underbid[:price] - @step
            else
              offer[:price] = inside_contigent.sort_by{|o| -o[:price]}.first[:price]
            end
          else
            offer[:price] = offer[:min_price]
          end
        end
      end
    end
  end

  def i_am_changer?(offer)
    inside_contigent_capacity = @offers.select{|o| o[:id] != offer[:id] && o[:status] == "inside_contigent"}.map{|o| o[:delivery_quantity]}.sum
    if (offer[:delivery_quantity] + inside_contigent_capacity) <= @capacity
      false
    else
      true
    end
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

  def set_inside_to_maximum
    price_to_set = @offers.select{|o| o[:status] == 'outside_contigent'}.sort_by{|o| o[:price]}.first[:price]
    @offers.select{|o| o[:status] == 'inside_contigent'}.each do |o|
      if (price_to_set - @step) > o[:min_price]
        o[:price] = price_to_set - @step
      end
    end
  end
end



@s = AutoBidService.new

@s.scenario_one

#@s.scenario_two

#@s.scenario_three

#@s.scenario_four

@s.autobid
@s.ranking
@s.set_inside_to_maximum


@s.print


